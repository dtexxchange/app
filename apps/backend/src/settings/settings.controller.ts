import { Controller, Get, Body, Patch, Post, Delete, Param, UseGuards, Req } from '@nestjs/common';
import { SettingsService } from './settings.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('settings')
export class SettingsController {
  constructor(private settingsService: SettingsService) {}

  @Get('wallets')
  @UseGuards(JwtAuthGuard)
  async getActiveWallets() {
    return this.settingsService.getActiveWallets();
  }

  @Get('admin/wallets')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async getAllWallets() {
    return this.settingsService.getAllWallets();
  }

  @Post('admin/wallets')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async createWallet(@Body('address') address: string, @Body('network') network: string) {
    return this.settingsService.createWallet(address, network || 'TRC20');
  }

  @Patch('admin/wallets/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async updateWallet(@Param('id') id: string, @Body() data: { address?: string; network?: string; isActive?: boolean }) {
    return this.settingsService.updateWallet(id, data);
  }

  @Delete('admin/wallets/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async deleteWallet(@Param('id') id: string) {
    return this.settingsService.deleteWallet(id);
  }

  @Get('conversion-rate')
  @UseGuards(JwtAuthGuard)
  async getConversionRate() {
    return this.settingsService.getConversionRate();
  }

  @Get('conversion-rate/history')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async getConversionRateHistory() {
    return this.settingsService.getConversionRateHistory();
  }

  @Patch('conversion-rate')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async updateConversionRate(@Body('rate') rate: number, @Req() req: any) {
    return this.settingsService.updateConversionRate(rate, req.user.email);
  }
}
