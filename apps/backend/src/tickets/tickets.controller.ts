import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Req,
  Query,
} from '@nestjs/common';
import { TicketsService } from './tickets.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role, TicketStatus } from '@prisma/client';

@Controller('tickets')
@UseGuards(JwtAuthGuard)
export class TicketsController {
  constructor(private ticketsService: TicketsService) {}

  @Post()
  async createTicket(
    @Req() req: any,
    @Body('subject') subject: string,
    @Body('description') description: string,
  ) {
    return this.ticketsService.createTicket(req.user.userId, subject, description);
  }

  @Get()
  async listTickets(
    @Req() req: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: TicketStatus,
    @Query('search') search?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 10;
    return this.ticketsService.listTickets(
      req.user.userId,
      req.user.role as Role,
      pageNum,
      limitNum,
      status,
      search,
    );
  }

  @Get(':id')
  async getTicket(@Param('id') id: string, @Req() req: any) {
    return this.ticketsService.getTicket(id, req.user.userId, req.user.role as Role);
  }

  @Get(':id/messages')
  async getTicketMessages(
    @Param('id') id: string,
    @Req() req: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    return this.ticketsService.getTicketMessages(
      id,
      req.user.userId,
      req.user.role as Role,
      pageNum,
      limitNum,
    );
  }

  @Post(':id/messages')
  async addMessage(
    @Param('id') id: string,
    @Req() req: any,
    @Body('message') message: string,
  ) {
    return this.ticketsService.addMessage(
      id,
      req.user.userId,
      message,
      req.user.role as Role,
    );
  }

  @Patch(':id/status')
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  async updateStatus(
    @Param('id') id: string,
    @Req() req: any,
    @Body('status') status: TicketStatus,
  ) {
    return this.ticketsService.updateStatus(id, status, req.user.userId);
  }
}
