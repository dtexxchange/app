import { Injectable, OnModuleInit } from '@nestjs/common';
import { Role } from '@prisma/client';
import { EmailService } from '../email/email.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class SettingsService implements OnModuleInit {
  constructor(
    private prisma: PrismaService,
    private emailService: EmailService,
    private notificationsService: NotificationsService,
  ) {}

  async onModuleInit() {
    // Initialize global settings if not exists
    await this.prisma.globalSettings.upsert({
      where: { id: 'global_settings' },
      update: {},
      create: { id: 'global_settings', usdtToInrRate: null },
    });

    // Seed default support contacts if table is empty
    const count = await this.prisma.supportContact.count();
    if (count === 0) {
      await this.prisma.supportContact.createMany({
        data: [
          { title: 'Telegram Support', platform: 'TELEGRAM', url: '@Support' },
          { title: 'WhatsApp Hotline', platform: 'WHATSAPP', url: '+1234567890' },
        ],
      });
    }
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

        const userName = (assignmentRecord.user.firstName || assignmentRecord.user.lastName)
          ? `${assignmentRecord.user.firstName ?? ''} ${assignmentRecord.user.lastName ?? ''}`.trim()
          : assignmentRecord.user.email;

        for (const admin of admins) {
          this.emailService.sendAssignmentAlert(
            admin.email,
            userName,
            assignmentRecord.wallet.address,
            assignmentRecord.wallet.name ||
              `${assignmentRecord.wallet.network} Gateway`,
          );
        }

        await this.notificationsService.notifyAdmins(
          'QR Assignment Alert',
          `User ${userName} has viewed the deposit QR code.`,
          'QR_ASSIGNMENT',
          assignmentRecord.id,
        );

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

  async getWithdrawalFee() {
    const settings = await this.prisma.globalSettings.findUnique({
      where: { id: 'global_settings' },
    });
    return { withdrawalFee: settings?.withdrawalFee };
  }

  async updateWithdrawalFee(fee: number, adminEmail: string) {
    const roundedFee = Math.round(fee * 100) / 100;
    return this.prisma.$transaction(async (tx) => {
      const settings = await tx.globalSettings.update({
        where: { id: 'global_settings' },
        data: { withdrawalFee: roundedFee },
      });

      await tx.withdrawalFeeHistory.create({
        data: {
          fee: roundedFee,
          adminEmail: adminEmail,
        },
      });

      return settings;
    });
  }

  async getWithdrawalFeeHistory() {
    return this.prisma.withdrawalFeeHistory.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async getHelpTelegram() {
    const contacts = await this.getSupportContacts();
    const telegram = contacts.find((c) => c.platform === 'TELEGRAM');
    return { helpTelegram: telegram?.url || '' };
  }

  async updateHelpTelegram(telegram: string) {
    const contacts = await this.getSupportContacts();
    const telegramContact = contacts.find((c) => c.platform === 'TELEGRAM');
    if (telegramContact) {
      return this.updateSupportContact(telegramContact.id, { url: telegram });
    } else {
      return this.createSupportContact('Telegram Support', 'TELEGRAM', telegram);
    }
  }

  async getSupportContacts() {
    return this.prisma.supportContact.findMany({
      orderBy: { createdAt: 'asc' },
    });
  }

  async createSupportContact(title: string, platform: string, url: string) {
    return this.prisma.supportContact.create({
      data: { title, platform, url },
    });
  }

  async updateSupportContact(
    id: string,
    data: { title?: string; platform?: string; url?: string },
  ) {
    return this.prisma.supportContact.update({
      where: { id },
      data,
    });
  }

  async deleteSupportContact(id: string) {
    return this.prisma.supportContact.delete({
      where: { id },
    });
  }
}
