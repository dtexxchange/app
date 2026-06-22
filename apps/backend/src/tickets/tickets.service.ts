import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { EmailService } from '../email/email.service';
import { Role, TicketStatus } from '@prisma/client';

@Injectable()
export class TicketsService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
    private emailService: EmailService,
  ) {}

  async createTicket(userId: string, subject: string, description: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Create ticket & initial message in a transaction
    const ticket = await this.prisma.ticket.create({
      data: {
        subject,
        status: TicketStatus.OPEN,
        userId,
        messages: {
          create: {
            senderId: userId,
            message: description,
          },
        },
      },
      include: {
        messages: true,
      },
    });

    const readableIdStr = ticket.readableId.toString();

    // 1. Notify all admins in-app
    await this.notificationsService.notifyAdmins(
      `New Ticket #${readableIdStr} Raised`,
      `Subject: ${subject}\nFrom: ${user.email}`,
      'TICKET_UPDATE',
      ticket.id,
    );

    // 2. Notify all admins by email
    const admins = await this.prisma.user.findMany({
      where: { role: Role.ADMIN },
    });

    for (const admin of admins) {
      await this.emailService.sendTicketCreatedAdminAlert(
        admin.email,
        readableIdStr,
        subject,
        user.email,
        description,
      );
    }

    return this.serializeTicket(ticket);
  }

  async listTickets(
    userId: string,
    role: Role,
    page: number,
    limit: number,
    status?: TicketStatus,
    search?: string,
  ) {
    const where: any = {};
    if (role !== Role.ADMIN) {
      where.userId = userId;
    }

    if (status) {
      where.status = status;
    }

    if (search && search.trim() !== '') {
      const queryStr = search.trim();
      const conditions: any[] = [
        { subject: { contains: queryStr, mode: 'insensitive' } },
        {
          user: {
            email: { contains: queryStr, mode: 'insensitive' },
          },
        },
      ];
      const searchAsNumber = /^\d+$/.test(queryStr) ? BigInt(queryStr) : undefined;
      if (searchAsNumber !== undefined) {
        conditions.push({ readableId: searchAsNumber });
      }
      where.OR = conditions;
    }

    const tickets = await this.prisma.ticket.findMany({
      where,
      take: limit,
      skip: (page - 1) * limit,
      include: {
        user: {
          select: {
            email: true,
            firstName: true,
            lastName: true,
          },
        },
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return tickets.map((t) => this.serializeTicket(t));
  }

  async getTicket(ticketId: string, userId: string, role: Role) {
    const ticket = await this.prisma.ticket.findUnique({
      where: { id: ticketId },
      include: {
        user: {
          select: {
            email: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    if (role !== Role.ADMIN && ticket.userId !== userId) {
      throw new ForbiddenException('You do not have access to this ticket');
    }

    return this.serializeTicket(ticket);
  }

  async getTicketMessages(
    ticketId: string,
    userId: string,
    role: Role,
    page: number,
    limit: number,
  ) {
    const ticket = await this.prisma.ticket.findUnique({
      where: { id: ticketId },
    });

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    if (role !== Role.ADMIN && ticket.userId !== userId) {
      throw new ForbiddenException('You do not have access to this ticket');
    }

    const messages = await this.prisma.ticketMessage.findMany({
      where: { ticketId },
      take: limit,
      skip: (page - 1) * limit,
      orderBy: { createdAt: 'desc' },
      include: {
        sender: {
          select: {
            email: true,
            role: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    return messages;
  }

  async addMessage(ticketId: string, senderId: string, message: string, role: Role) {
    const ticket = await this.prisma.ticket.findUnique({
      where: { id: ticketId },
      include: { user: true },
    });

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    if (role !== Role.ADMIN && ticket.userId !== senderId) {
      throw new ForbiddenException('You cannot reply to this ticket');
    }

    const sender = await this.prisma.user.findUnique({ where: { id: senderId } });
    if (!sender) {
      throw new NotFoundException('Sender not found');
    }

    // If message is from user and ticket was not OPEN, reopen it
    const shouldReopen = role === Role.USER && ticket.status !== TicketStatus.OPEN;

    const [ticketMessage, updatedTicket] = await this.prisma.$transaction([
      this.prisma.ticketMessage.create({
        data: {
          ticketId,
          senderId,
          message,
        },
        include: {
          sender: {
            select: {
              email: true,
              role: true,
              firstName: true,
              lastName: true,
            },
          },
        },
      }),
      this.prisma.ticket.update({
        where: { id: ticketId },
        data: {
          status: shouldReopen ? TicketStatus.OPEN : undefined,
          updatedAt: new Date(),
        },
      }),
    ]);

    const readableIdStr = updatedTicket.readableId.toString();

    // Trigger Notifications & Emails
    if (role === Role.USER) {
      // Notify admins
      await this.notificationsService.notifyAdmins(
        `Reply on Ticket #${readableIdStr}`,
        `${sender.email}: ${message}`,
        'TICKET_UPDATE',
        ticket.id,
      );

      const admins = await this.prisma.user.findMany({
        where: { role: Role.ADMIN },
      });
      for (const admin of admins) {
        await this.emailService.sendTicketReplyAlert(
          admin.email,
          sender.email,
          readableIdStr,
          ticket.subject,
          message,
          true,
        );
      }
    } else {
      // Notify the ticket raising user
      await this.notificationsService.createNotification(
        ticket.userId,
        `New Support Reply - Ticket #${readableIdStr}`,
        `Admin: ${message}`,
        'TICKET_UPDATE',
        ticket.id,
      );

      await this.emailService.sendTicketReplyAlert(
        ticket.user.email,
        sender.email,
        readableIdStr,
        ticket.subject,
        message,
        false,
      );
    }

    return ticketMessage;
  }

  async updateStatus(ticketId: string, status: TicketStatus, adminUserId: string) {
    const admin = await this.prisma.user.findUnique({ where: { id: adminUserId } });
    if (!admin || admin.role !== Role.ADMIN) {
      throw new ForbiddenException('Only administrators can update ticket status');
    }

    const ticket = await this.prisma.ticket.findUnique({
      where: { id: ticketId },
      include: { user: true },
    });

    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    const updatedTicket = await this.prisma.ticket.update({
      where: { id: ticketId },
      data: { status },
    });

    const readableIdStr = updatedTicket.readableId.toString();
    const statusText = status === TicketStatus.RESOLVED ? 'RESOLVED' : 'CANNOT BE RESOLVED';

    // 1. Notify user in-app
    await this.notificationsService.createNotification(
      ticket.userId,
      `Ticket #${readableIdStr} Status Update`,
      `Your ticket has been marked as ${statusText}`,
      'TICKET_UPDATE',
      ticket.id,
    );

    // 2. Email user
    await this.emailService.sendTicketStatusAlert(
      ticket.user.email,
      readableIdStr,
      ticket.subject,
      status,
    );

    return this.serializeTicket(updatedTicket);
  }

  // Serialization helper to convert BigInt readableId to string
  private serializeTicket(ticket: any) {
    if (!ticket) return null;
    return {
      ...ticket,
      readableId: ticket.readableId.toString(),
    };
  }
}
