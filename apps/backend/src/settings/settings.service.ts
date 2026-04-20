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
    const now = new Date();

    // Check if there is an active assignment
    const assignment = await this.prisma.walletAssignment.findFirst({
      where: { userId, expiresAt: { gt: now } },
      orderBy: { createdAt: 'desc' },
    });

    if (assignment) {
      // Find the wallet assigned
      const wallet = await this.prisma.globalWallet.findUnique({
        where: { id: assignment.walletId, isActive: true },
      });

      if (wallet) {
        return {
          ...wallet,
          expiresAt: assignment.expiresAt,
        };
      }
    }

    // No active assignment or wallet became inactive, pick a new one
    const activeWallets = await this.prisma.globalWallet.findMany({
      where: { isActive: true },
    });

    if (activeWallets.length === 0) {
      return null;
    }

    // Pick a random wallet
    const randomWallet =
      activeWallets[Math.floor(Math.random() * activeWallets.length)];

    // Set expiry to 30 minutes from now
    const expiresAt = new Date(now.getTime() + 30 * 60 * 1000);

    // ALWAYS CREATE a new assignment to keep history
    const assignmentRecord = await this.prisma.walletAssignment.create({
      data: {
        userId,
        walletId: randomWallet.id,
        expiresAt,
      },
      include: {
        wallet: true,
        user: true,
      },
    });

    // Notify Admins
    const admins = await this.prisma.user.findMany({
      where: { role: Role.ADMIN },
    });

    for (const admin of admins) {
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
