import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Role, TransactionStatus } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { WalletService } from './wallet.service';

@Controller('wallet')
@UseGuards(JwtAuthGuard, RolesGuard)
export class WalletController {
  constructor(private walletService: WalletService) {}

  @Post('admin/deposit')
  @Roles(Role.ADMIN)
  async adminDeposit(
    @Request() req,
    @Body() data: { userId: string; amount: number },
  ) {
    return this.walletService.adminDeposit(
      data.userId,
      data.amount,
      req.user.email,
    );
  }

  @Post('exchange')
  async exchange(
    @Request() req,
    @Body('amount') amount: number,
    @Body('bankDetails') bankDetails: string,
    @Body('passcode') passcode: string,
  ) {
    return this.walletService.exchange(
      req.user.userId,
      amount,
      bankDetails,
      req.user.email,
      passcode,
    );
  }

  @Get('transactions')
  async getTransactions(
    @Request() req,
    @Query('status') status?: TransactionStatus,
    @Query('type') type?: string,
    @Query('userId') reqUserId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.walletService.getTransactions(
      req.user.userId,
      req.user.role,
      status,
      type,
      reqUserId,
      page ? parseInt(page, 10) : undefined,
      limit ? parseInt(limit, 10) : undefined,
    );
  }

  @Get('transactions/:id')
  async getTransaction(@Request() req, @Param('id') id: string) {
    return this.walletService.getTransaction(
      id,
      req.user.userId,
      req.user.role,
    );
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
