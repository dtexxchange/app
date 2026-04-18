import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { BankAccountsService } from './bank-accounts.service';

@Controller('bank-accounts')
@UseGuards(JwtAuthGuard)
export class BankAccountsController {
  constructor(private readonly bankAccountsService: BankAccountsService) {}

  @Post()
  create(
    @Request() req,
    @Body()
    data: { name: string; bankName: string; accountNo: string; ifsc: string },
  ) {
    return this.bankAccountsService.create(req.user.userId, data);
  }

  @Get()
  findAll(@Request() req) {
    return this.bankAccountsService.findAll(req.user.userId);
  }

  @Patch(':id')
  update(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.bankAccountsService.update(req.user.userId, id, data);
  }

  @Delete(':id')
  remove(@Request() req, @Param('id') id: string) {
    return this.bankAccountsService.remove(req.user.userId, id);
  }

  @Get(':id/logs')
  getLogs(@Request() req, @Param('id') id: string) {
    return this.bankAccountsService.getLogs(req.user.userId, id);
  }
}
