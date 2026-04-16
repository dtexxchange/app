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
      create: { id: 'global_settings', walletId: null },
    });
  }

  async getWalletId() {
    const settings = await this.prisma.globalSettings.findUnique({
      where: { id: 'global_settings' },
    });
    return { walletId: settings?.walletId };
  }

  async updateWalletId(walletId: string) {
    return this.prisma.globalSettings.update({
      where: { id: 'global_settings' },
      data: { walletId },
    });
  }
}
