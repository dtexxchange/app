import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SettingsService implements OnModuleInit {
  constructor(private prisma: PrismaService) {}

  async onModuleInit() {
    // Initialize global settings if not exists
    await this.prisma.globalSettings.upsert({
      where: { id: 'global_settings' },
      update: {},
      create: { id: 'global_settings', usdtToInrRate: null },
    });
  }

  async getAllWallets() {
    return this.prisma.globalWallet.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async getActiveWallets() {
    return this.prisma.globalWallet.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createWallet(address: string, network: string = 'TRC20') {
    return this.prisma.globalWallet.create({
      data: { address, network, isActive: true },
    });
  }

  async updateWallet(id: string, data: { address?: string; network?: string; isActive?: boolean }) {
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
    return this.prisma.$transaction(async (tx) => {
      const settings = await tx.globalSettings.update({
        where: { id: 'global_settings' },
        data: { usdtToInrRate: rate },
      });

      await tx.conversionRateHistory.create({
        data: {
          rate: rate,
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
