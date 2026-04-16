import { Controller, Get, Post, Body, Patch, Param, UseGuards, Request, Query } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role, TransactionStatus } from '@prisma/client';

@Controller('wallet')
@UseGuards(JwtAuthGuard, RolesGuard)
export class WalletController {
  constructor(private walletService: WalletService) {}

  @Post('deposit')
  async deposit(@Request() req, @Body('amount') amount: number) {
    return this.walletService.deposit(req.user.userId, amount, req.user.email);
  }

  @Post('withdraw')
  async withdraw(
    @Request() req,
    @Body('amount') amount: number,
    @Body('bankDetails') bankDetails: string,
  ) {
    return this.walletService.withdraw(req.user.userId, amount, bankDetails, req.user.email);
  }

  @Get('transactions')
  async getTransactions(
    @Request() req,
    @Query('status') status?: TransactionStatus,
    @Query('type') type?: string,
    @Query('userId') reqUserId?: string,
  ) {
    return this.walletService.getTransactions(req.user.userId, req.user.role, status, type, reqUserId);
  }

  @Get('transactions/:id')
  async getTransaction(@Request() req, @Param('id') id: string) {
    return this.walletService.getTransaction(id, req.user.userId, req.user.role);
  }

  @Patch('transactions/:id/status')
  @Roles(Role.ADMIN)
  async updateStatus(
    @Param('id') id: string,
    @Body('status') status: TransactionStatus,
    @Request() req,
  ) {
    return this.walletService.updateStatus(id, status, req.user.email);
  }

  @Post('admin/public-key')
  @Roles(Role.ADMIN)
  async setPublicKey(@Body('publicKey') publicKey: string) {
    return this.walletService.setPublicKey(publicKey);
  }

  @Get('admin/public-key')
  async getPublicKey() {
    return this.walletService.getPublicKey();
  }
}
