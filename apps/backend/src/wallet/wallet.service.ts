import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TransactionType, TransactionStatus } from '@prisma/client';

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

  // ─── Deposit ──────────────────────────────────────────────────────────────────
  async deposit(userId: string, amount: number, userEmail: string) {
    if (amount <= 0) throw new BadRequestException('Invalid amount');
    return this.prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.create({
        data: {
          userId,
          type: TransactionType.DEPOSIT,
          amount,
          status: TransactionStatus.PENDING,
        },
      });
      await this.writeLog(tx, transaction.id, TransactionStatus.PENDING, userEmail, 'Deposit request submitted');
      return transaction;
    });
  }

  // ─── Withdraw ─────────────────────────────────────────────────────────────────
  async withdraw(userId: string, amount: number, encryptedBankDetails: string, userEmail: string) {
    if (amount <= 0) throw new BadRequestException('Invalid amount');
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (user.balance < amount) throw new BadRequestException('Insufficient balance');

    return this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: { balance: { decrement: amount } },
      });
      const transaction = await tx.transaction.create({
        data: {
          userId,
          type: TransactionType.WITHDRAW,
          amount,
          status: TransactionStatus.PENDING,
          bankDetails: encryptedBankDetails,
        },
      });
      await this.writeLog(tx, transaction.id, TransactionStatus.PENDING, userEmail, 'Withdrawal request submitted');
      return transaction;
    });
  }

  // ─── Get all transactions ─────────────────────────────────────────────────────
  async getTransactions(userId: string, role: string, status?: TransactionStatus, type?: string, reqUserId?: string) {
    const whereClause: any = {};
    if (status) whereClause.status = status;
    if (type) whereClause.type = type as TransactionType;

    if (role === 'ADMIN') {
      if (reqUserId) whereClause.userId = reqUserId;
      return this.prisma.transaction.findMany({
        where: whereClause,
        orderBy: { createdAt: 'desc' },
        include: this.includeLogsAndUser,
      });
    }

    whereClause.userId = userId;
    return this.prisma.transaction.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      include: this.includeLogsAndUser,
    });
  }

  // ─── Get single transaction ───────────────────────────────────────────────────
  async getTransaction(transactionId: string, userId: string, role: string) {
    const tx = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
      include: this.includeLogsAndUser,
    });
    if (!tx) throw new NotFoundException('Transaction not found');
    if (role !== 'ADMIN' && tx.userId !== userId) throw new NotFoundException('Transaction not found');
    return tx;
  }

  // ─── Update status ────────────────────────────────────────────────────────────
  async updateStatus(transactionId: string, status: TransactionStatus, adminEmail: string) {
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
        // Withdrawal balance was already deducted on request
      } else if (status === TransactionStatus.REJECTED) {
        if (transaction.type === TransactionType.WITHDRAW) {
          await tx.user.update({
            where: { id: transaction.userId },
            data: { balance: { increment: transaction.amount } },
          });
        }
      }

      const note =
        status === TransactionStatus.COMPLETED
          ? transaction.type === TransactionType.DEPOSIT ? 'Deposit approved and funds credited' : 'Withdrawal approved and processed'
          : transaction.type === TransactionType.WITHDRAW ? 'Withdrawal rejected and balance refunded' : 'Deposit rejected';

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
    const key = await this.prisma.adminPublicKey.findFirst({ orderBy: { createdAt: 'desc' } });
    if (!key) throw new NotFoundException('Admin has not set a public key yet');
    return key;
  }
}
