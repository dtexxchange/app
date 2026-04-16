import { Controller, Get, Body, Patch, UseGuards } from '@nestjs/common';
import { SettingsService } from './settings.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('settings')
export class SettingsController {
  constructor(private settingsService: SettingsService) {}

  @Get('wallet-id')
  @UseGuards(JwtAuthGuard)
  async getWalletId() {
    return this.settingsService.getWalletId();
  }

  @Patch('wallet-id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async updateWalletId(@Body('walletId') walletId: string) {
    return this.settingsService.updateWalletId(walletId);
  }
}
