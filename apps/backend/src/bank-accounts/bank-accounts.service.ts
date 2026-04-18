// Bank Account management service with audit logging
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class BankAccountsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, data: { name: string; bankName: string; accountNo: string; ifsc: string }) {
    return this.prisma.$transaction(async (tx) => {
      const account = await tx.bankAccount.create({
        data: { ...data, userId },
      });

      await tx.bankAccountLog.create({
        data: {
          bankAccountId: account.id,
          action: 'CREATE',
          changes: JSON.stringify(data),
        },
      });

      return account;
    });
  }

  async findAll(userId: string) {
    return this.prisma.bankAccount.findMany({
      where: { userId, isDeleted: false },
      orderBy: { createdAt: 'desc' },
    });
  }

  async update(userId: string, id: string, data: Partial<{ name: string; bankName: string; accountNo: string; ifsc: string }>) {
    const account = await this.prisma.bankAccount.findFirst({ where: { id, userId, isDeleted: false } });
    if (!account) throw new NotFoundException('Bank account not found');

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.bankAccount.update({
        where: { id },
        data,
      });

      await tx.bankAccountLog.create({
        data: {
          bankAccountId: id,
          action: 'UPDATE',
          changes: JSON.stringify({ ...data, _previous: account }),
        },
      });

      return updated;
    });
  }

  async remove(userId: string, id: string) {
    const account = await this.prisma.bankAccount.findFirst({ where: { id, userId, isDeleted: false } });
    if (!account) throw new NotFoundException('Bank account not found');

    return this.prisma.$transaction(async (tx) => {
      const deleted = await tx.bankAccount.update({
        where: { id },
        data: { isDeleted: true },
      });

      await tx.bankAccountLog.create({
        data: {
          bankAccountId: id,
          action: 'DELETE',
        },
      });

      return deleted;
    });
  }

  async getLogs(userId: string, id: string) {
    const account = await this.prisma.bankAccount.findFirst({ where: { id, userId } });
    if (!account) throw new NotFoundException('Bank account not found');

    return this.prisma.bankAccountLog.findMany({
      where: { bankAccountId: id },
      orderBy: { createdAt: 'desc' },
    });
  }
}
