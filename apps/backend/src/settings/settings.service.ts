import { Injectable, OnModuleInit } from '@nestjs/common';
import { Role } from '@prisma/client';
import { EmailService } from '../email/email.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SettingsService implements OnModuleInit {
  constructor(
    private prisma: PrismaService,
    private emailService: EmailService,
  ) {}

  async onModuleInit() {
    // Initialize global settings if not exists
    await this.prisma.globalSettings.upsert({
      where: { id: 'global_settings' },
      update: {},
      create: { id: 'global_settings', usdtToInrRate: null },
    });
  }

  async getAllWallets() {
    const now = new Date();
    return this.prisma.globalWallet.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: {
            assignments: {
              where: {
                expiresAt: { gt: now },
              },
            },
          },
        },
      },
    });
  }

  async getActiveWallets() {
    return this.prisma.globalWallet.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAssignedWallet(userId: string) {
    if (!userId) return null;

    return await this.prisma.$transaction(async (tx) => {
      const now = new Date();

      // 1. Check if user ALREADY has an active assignment
      const currentAssignment = await tx.walletAssignment.findFirst({
        where: { userId, expiresAt: { gt: now } },
        include: { wallet: true },
        orderBy: { createdAt: 'desc' },
      });

      if (currentAssignment && currentAssignment.wallet.isActive) {
        return {
          ...currentAssignment.wallet,
          expiresAt: currentAssignment.expiresAt,
        };
      }

      // 2. User doesn't have an active assignment. Find an unassigned active wallet.
      const activeWallets = await tx.globalWallet.findMany({
        where: { isActive: true },
      });

      if (activeWallets.length === 0) {
        return null;
      }

      // Find wallets that are currently assigned to SOMEONE ELSE
      const activeAssignments = await tx.walletAssignment.findMany({
        where: { expiresAt: { gt: now } },
        select: { walletId: true },
      });
      const assignedWalletIds = activeAssignments.map((a) => a.walletId);

      const availableWallets = activeWallets.filter(
        (w) => !assignedWalletIds.includes(w.id),
      );

      if (availableWallets.length > 0) {
        // Pick one (randomly)
        const walletToAssign =
          availableWallets[Math.floor(Math.random() * availableWallets.length)];
        const expiresAt = new Date(now.getTime() + 30 * 60 * 1000);

        const assignmentRecord = await tx.walletAssignment.create({
          data: {
            userId,
            walletId: walletToAssign.id,
            expiresAt,
          },
          include: { wallet: true, user: true },
        });

        // Notify Admins
        const admins = await tx.user.findMany({
          where: { role: Role.ADMIN },
        });

        for (const admin of admins) {
          // We can call this outside if we want, but inside is fine for consistency
          this.emailService.sendAssignmentAlert(
            admin.email,
            assignmentRecord.user.email,
            assignmentRecord.wallet.address,
            assignmentRecord.wallet.name ||
              `${assignmentRecord.wallet.network} Gateway`,
          );
        }

        return {
          ...assignmentRecord.wallet,
          expiresAt: assignmentRecord.expiresAt,
        };
      }

      // 3. All wallets are busy. Find when the next one becomes available.
      const soonestExpiry = await tx.walletAssignment.findFirst({
        where: { wallet: { isActive: true }, expiresAt: { gt: now } },
        orderBy: { expiresAt: 'asc' },
        select: { expiresAt: true },
      });

      return {
        isBusy: true,
        availableAt: soonestExpiry?.expiresAt || null,
      };
    });
  }

  async getActiveAssignments() {
    return this.prisma.walletAssignment.findMany({
      include: {
        user: {
          select: {
            email: true,
            firstName: true,
            lastName: true,
          },
        },
        wallet: true,
      },
      orderBy: { createdAt: 'desc' }, // Switched to createdAt desc to see latest first
      take: 100, // Show last 100 assignments
    });
  }

  async createWallet(
    address: string,
    network: string = 'TRC20',
    name?: string,
  ) {
    return this.prisma.globalWallet.create({
      data: { address, network, name, isActive: true },
    });
  }

  async updateWallet(
    id: string,
    data: {
      address?: string;
      network?: string;
      isActive?: boolean;
      name?: string;
    },
  ) {
    return this.prisma.globalWallet.update({
      where: { id },
      data,
    });
  }

  async deleteWallet(id: string) {
    return this.prisma.globalWallet.delete({
      where: { id },
    });
  }

  async getConversionRate() {
    const settings = await this.prisma.globalSettings.findUnique({
      where: { id: 'global_settings' },
    });
    return { usdtToInrRate: settings?.usdtToInrRate };
  }

  async updateConversionRate(rate: number, adminEmail: string) {
    const roundedRate = Math.round(rate * 100) / 100;
    return this.prisma.$transaction(async (tx) => {
      const settings = await tx.globalSettings.update({
        where: { id: 'global_settings' },
        data: { usdtToInrRate: roundedRate },
      });

      await tx.conversionRateHistory.create({
        data: {
          rate: roundedRate,
          adminEmail: adminEmail,
        },
      });

      return settings;
    });
  }

  async getConversionRateHistory() {
    return this.prisma.conversionRateHistory.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }
}
