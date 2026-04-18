import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { TransactionStatus, TransactionType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WalletService {
  public static readonly ENABLE_E2EE = false;
  constructor(private prisma: PrismaService) {}

  private includeLogsAndUser = {
    user: { select: { email: true } },
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
    if (amount <= 0) throw new BadRequestException('Invalid amount');

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    return this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: { balance: { increment: amount } },
      });

      const transaction = await tx.transaction.create({
        data: {
          userId,
          type: TransactionType.DEPOSIT,
          amount,
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
    if (amount <= 0) throw new BadRequestException('Invalid amount');

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

    return this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: { balance: { decrement: amount } },
      });
      const transaction = await tx.transaction.create({
        data: {
          userId,
          type: TransactionType.EXCHANGE,
          amount,
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
  }

  // ─── Get all transactions ─────────────────────────────────────────────────────
  async getTransactions(
    userId: string,
    role: string,
    status?: TransactionStatus,
    type?: string,
    reqUserId?: string,
    page?: number,
    limit?: number,
  ) {
    const whereClause: any = {};
    if (status) whereClause.status = status;
    if (type) whereClause.type = type as TransactionType;

    // Build args imperatively to avoid union-spread incompatibility with Prisma's strict overloads
    const baseArgs: Parameters<typeof this.prisma.transaction.findMany>[0] = {
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      include: this.includeLogsAndUser,
    };
    if (limit !== undefined) {
      baseArgs.take = limit;
      baseArgs.skip = page !== undefined ? (page - 1) * limit : 0;
    }

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
      include: this.includeLogsAndUser,
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
  ) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });

    if (!transaction) throw new NotFoundException('Transaction not found');
    if (transaction.status !== TransactionStatus.PENDING) {
      throw new BadRequestException('Transaction already processed');
    }

    return this.prisma.$transaction(async (tx) => {
      if (status === TransactionStatus.COMPLETED) {
        if (transaction.type === TransactionType.DEPOSIT) {
          await tx.user.update({
            where: { id: transaction.userId },
            data: { balance: { increment: transaction.amount } },
          });
        }
        // Exchange balance was already deducted on request
      } else if (status === TransactionStatus.REJECTED) {
        if (transaction.type === TransactionType.EXCHANGE) {
          await tx.user.update({
            where: { id: transaction.userId },
            data: { balance: { increment: transaction.amount } },
          });
        }
      }

      const note =
        status === TransactionStatus.COMPLETED
          ? transaction.type === TransactionType.DEPOSIT
            ? 'Deposit approved and funds credited'
            : 'Exchange approved and processed'
          : transaction.type === TransactionType.EXCHANGE
            ? 'Exchange rejected and balance refunded'
            : 'Deposit rejected';

      await this.writeLog(tx, transactionId, status, adminEmail, note);

      return tx.transaction.update({
        where: { id: transactionId },
        data: { status },
        include: this.includeLogsAndUser,
      });
    });
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
