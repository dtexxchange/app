import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { TransactionStatus, TransactionType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class WalletService {
  public static readonly ENABLE_E2EE = false;
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  private transactionSelect = {
    id: true,
    readableId: true,
    userId: true,
    type: true,
    amount: true,
    status: true,
    bankDetails: true,
    conversionRate: true,
    utr: true,
    createdAt: true,
    updatedAt: true,
    user: { select: { email: true, firstName: true, lastName: true, readableId: true } },
    relatedUser: { select: { email: true, firstName: true, lastName: true, readableId: true } },
    logs: { orderBy: { createdAt: 'asc' as const } },
  };

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  private async writeLog(
    tx: any,
    transactionId: string,
    status: TransactionStatus,
    actor: string,
    note?: string,
  ) {
    return tx.transactionLog.create({
      data: { transactionId, status, actor, note },
    });
  }

  // ─── Admin Deposit ────────────────────────────────────────────────────────────
  async adminDeposit(userId: string, amount: number, adminEmail: string) {
    const roundedAmount = Math.round(amount * 100) / 100;
    if (roundedAmount <= 0) throw new BadRequestException('Invalid amount');

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    return this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: { balance: { increment: roundedAmount } },
      });

      const transaction = await tx.transaction.create({
        data: {
          userId,
          type: TransactionType.DEPOSIT,
          amount: roundedAmount,
          status: TransactionStatus.COMPLETED,
        },
      });
      await this.writeLog(
        tx,
        transaction.id,
        TransactionStatus.COMPLETED,
        adminEmail,
        'Manual deposit processed by admin',
      );
      return transaction;
    });
  }

  // ─── Exchange ─────────────────────────────────────────────────────────────────
  async exchange(
    userId: string,
    amount: number,
    encryptedBankDetails: string,
    userEmail: string,
    passcode: string,
  ) {
    const roundedAmount = Math.round(amount * 100) / 100;
    if (roundedAmount <= 0) throw new BadRequestException('Invalid amount');

    const settings = await this.prisma.globalSettings.findUnique({
      where: { id: 'global_settings' },
    });
    if (
      !settings ||
      settings.usdtToInrRate === null ||
      settings.usdtToInrRate === undefined
    ) {
      throw new BadRequestException(
        'Conversion rate not set by admin. Exchanges are currently disabled.',
      );
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    if (user.passcode && user.passcode !== passcode) {
      throw new BadRequestException('Invalid passcode for authorization');
    }

    if (user.balance < amount)
      throw new BadRequestException('Insufficient balance');

    const result = await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: { balance: { decrement: roundedAmount } },
      });
      const transaction = await tx.transaction.create({
        data: {
          userId,
          type: TransactionType.EXCHANGE,
          amount: roundedAmount,
          status: TransactionStatus.PENDING,
          bankDetails: encryptedBankDetails,
          conversionRate: settings.usdtToInrRate,
        },
      });
      await this.writeLog(
        tx,
        transaction.id,
        TransactionStatus.PENDING,
        userEmail,
        'Exchange request submitted',
      );
      return transaction;
    });

    await this.notificationsService.notifyAdmins(
      'New Exchange Request',
      `A new exchange request of ${roundedAmount} USDT has been submitted.`,
      'TRANSACTION_NEW',
      result.id,
    );

    return result;
  }

  // ─── Withdraw ─────────────────────────────────────────────────────────────────
  async withdraw(
    userId: string,
    amount: number,
    encryptedBankDetails: string,
    userEmail: string,
    passcode: string,
  ) {
    const roundedAmount = Math.round(amount * 100) / 100;
    if (roundedAmount <= 0) throw new BadRequestException('Invalid amount');

    const settings = await this.prisma.globalSettings.findUnique({
      where: { id: 'global_settings' },
    });
    if (!settings || settings.usdtToInrRate === null || settings.usdtToInrRate === undefined) {
      throw new BadRequestException('Conversion rate not set by admin. Withdrawals are currently disabled.');
    }

    const withdrawalFee = settings.withdrawalFee || 0;

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    if (user.passcode && user.passcode !== passcode) {
      throw new BadRequestException('Invalid passcode for authorization');
    }

    if (user.balance < roundedAmount) throw new BadRequestException('Insufficient balance');

    const result = await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: { balance: { decrement: roundedAmount } },
      });

      const transaction = await tx.transaction.create({
        data: {
          userId,
          type: TransactionType.WITHDRAWAL,
          amount: roundedAmount,
          fee: withdrawalFee,
          status: TransactionStatus.PENDING,
          bankDetails: encryptedBankDetails,
          conversionRate: settings.usdtToInrRate,
        },
      });

      await this.writeLog(
        tx,
        transaction.id,
        TransactionStatus.PENDING,
        userEmail,
        'Withdrawal request submitted',
      );

      return transaction;
    });

    await this.notificationsService.notifyAdmins(
      'New Withdrawal Request',
      `A new withdrawal request of ${roundedAmount} USDT has been submitted.`,
      'TRANSACTION_NEW',
      result.id,
    );

    return result;
  }

  // ─── Get all transactions ─────────────────────────────────────────────────────
  async getTransactions(
    userId: string,
    role: string,
    status?: TransactionStatus,
    type?: string,
    reqUserId?: string,
    relatedUserId?: string,
    page?: number,
    limit?: number,
  ) {
    const whereClause: any = {};
    if (status) whereClause.status = status;
    if (type) whereClause.type = type as TransactionType;
    if (relatedUserId) whereClause.relatedUserId = relatedUserId;

    const effectiveLimit = limit ?? 20;

    // Build args imperatively to avoid union-spread incompatibility with Prisma's strict overloads
    const baseArgs: Parameters<typeof this.prisma.transaction.findMany>[0] = {
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      select: this.transactionSelect,
      take: effectiveLimit,
      skip: page !== undefined ? (page - 1) * effectiveLimit : 0,
    };

    if (role === 'ADMIN') {
      if (reqUserId) (baseArgs.where as any).userId = reqUserId;
      return this.prisma.transaction.findMany(baseArgs);
    }

    (baseArgs.where as any).userId = userId;
    return this.prisma.transaction.findMany(baseArgs);
  }

  // ─── Get single transaction ───────────────────────────────────────────────────
  async getTransaction(transactionId: string, userId: string, role: string) {
    const tx = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
      select: this.transactionSelect,
    });
    if (!tx) throw new NotFoundException('Transaction not found');
    if (role !== 'ADMIN' && tx.userId !== userId)
      throw new NotFoundException('Transaction not found');
    return tx;
  }

  // ─── Update status ────────────────────────────────────────────────────────────
  async updateStatus(
    transactionId: string,
    status: TransactionStatus,
    adminEmail: string,
    utr?: string,
  ) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });

    if (!transaction) throw new NotFoundException('Transaction not found');
    if (transaction.status !== TransactionStatus.PENDING) {
      throw new BadRequestException('Transaction already processed');
    }

    if (status === TransactionStatus.COMPLETED && !utr) {
      throw new BadRequestException('UTR is mandatory for completing transactions');
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const roundedAmount = Math.round(transaction.amount * 100) / 100;
      if (status === TransactionStatus.COMPLETED) {
        if (transaction.type === TransactionType.DEPOSIT) {
          await tx.user.update({
            where: { id: transaction.userId },
            data: { balance: { increment: roundedAmount } },
          });
        }

        // --- Referral Commission Logic ---
        if (transaction.type === TransactionType.EXCHANGE) {
          const user = await tx.user.findUnique({
            where: { id: transaction.userId },
            select: { id: true, referredById: true, email: true, firstName: true, lastName: true },
          });

          if (user?.referredById) {
            const commission = Math.round(roundedAmount * 0.003 * 100) / 100;
            if (commission > 0) {
              await tx.user.update({
                where: { id: user.referredById },
                data: { balance: { increment: commission } },
              });

              const commTx = await tx.transaction.create({
                data: {
                  userId: user.referredById,
                  relatedUserId: user.id, // Store who triggered this
                  type: TransactionType.REFERRAL_COMMISSION,
                  amount: commission,
                  status: TransactionStatus.COMPLETED,
                },
              });

              const name = (user.firstName || user.lastName)
                ? `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim()
                : user.email;

              await this.writeLog(
                tx,
                commTx.id,
                TransactionStatus.COMPLETED,
                'SYSTEM',
                `Referral commission from ${name} exchange`,
              );
            }
          }
        }
        // ---------------------------------
      } else if (status === TransactionStatus.REJECTED) {
        if (
          transaction.type === TransactionType.EXCHANGE ||
          transaction.type === TransactionType.WITHDRAWAL
        ) {
          await tx.user.update({
            where: { id: transaction.userId },
            data: { balance: { increment: roundedAmount } },
          });
        }
      }

      const note =
        status === TransactionStatus.COMPLETED
          ? transaction.type === TransactionType.DEPOSIT
            ? 'Deposit approved and funds credited'
            : transaction.type === TransactionType.WITHDRAWAL
              ? 'Withdrawal approved and processed'
              : 'Exchange approved and processed'
          : transaction.type === TransactionType.EXCHANGE ||
              transaction.type === TransactionType.WITHDRAWAL
            ? `${transaction.type === TransactionType.WITHDRAWAL ? 'Withdrawal' : 'Exchange'} rejected and balance refunded`
            : 'Deposit rejected';

      await this.writeLog(tx, transactionId, status, adminEmail, note);

      return tx.transaction.update({
        where: { id: transactionId },
        data: { status, utr },
        select: this.transactionSelect,
      });
    });

    // Notify User
    const statusStr = status === TransactionStatus.COMPLETED ? 'Completed' : 'Rejected';
    const txTypeStr = result.type.charAt(0) + result.type.slice(1).toLowerCase();
    await this.notificationsService.createNotification(
      result.userId,
      `Transaction ${statusStr}`,
      `Your ${txTypeStr} transaction of ${result.amount} USDT has been ${status.toLowerCase()}.`,
      'TRANSACTION_STATUS',
      result.id,
    );

    return result;
  }

  // ─── Keys ─────────────────────────────────────────────────────────────────────
  async setPublicKey(publicKey: string) {
    await this.prisma.adminPublicKey.deleteMany({});
    return this.prisma.adminPublicKey.create({ data: { publicKey } });
  }

  async getPublicKey() {
    if (!WalletService.ENABLE_E2EE) {
      return { publicKey: 'E2EE_DISABLED_BY_FEATURE_FLAG' };
    }
    const key = await this.prisma.adminPublicKey.findFirst({
      orderBy: { createdAt: 'desc' },
    });
    if (!key) throw new NotFoundException('Admin has not set a public key yet');
    return key;
  }
}
