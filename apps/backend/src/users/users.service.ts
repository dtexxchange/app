import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Role, UserStatus } from '@prisma/client';
import { EmailService } from '../email/email.service';

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService,
    private emailService: EmailService,
  ) {}

  async create(email: string, role: Role = Role.USER, firstName?: string, lastName?: string) {
    const normalizedEmail = email.toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (existing) throw new ConflictException('User already exists');

    const userReferralCode = Math.random().toString(36).substring(2, 10).toUpperCase();

    return this.prisma.user.create({
      data: { 
        email: normalizedEmail, 
        role, 
        firstName,
        lastName,
        status: UserStatus.APPROVED, // When admin adds, it's auto-approved
        referralCode: userReferralCode
      },
    });
  }

  async findAll(search?: string, role?: Role) {
    const where: any = {};
    if (search) {
      where.email = { contains: search, mode: 'insensitive' };
    }
    if (role) {
      where.role = role;
    }
    return this.prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: { transactions: true }
        }
      }
    });
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { 
        transactions: {
            orderBy: { createdAt: 'desc' },
            take: 20
        },
        walletAssignment: {
            include: {
                wallet: true
            }
        }
      }
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId }
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateStatus(userId: string, status: UserStatus) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { status },
    });

    if (status === UserStatus.APPROVED) {
      this.emailService.sendApprovalEmail(user.email, user.firstName || 'User');
    }

    return user;
  }

  async getReferrals(userId: string) {
    return this.prisma.user.findMany({
      where: { referredById: userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        status: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' }
    });
  }
  async updatePasscode(userId: string, passcode: string, oldPasscode?: string) {
    if (!/^\d{6}$/.test(passcode)) {
        throw new ConflictException('Passcode must be purely 6 digits');
    }
    
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    if (user.passcode) {
        if (!oldPasscode) {
            throw new ConflictException('Old passcode is required to update');
        }
        if (user.passcode !== oldPasscode) {
            throw new ConflictException('Invalid old passcode');
        }
        if (user.passcode === passcode) {
            throw new ConflictException('New passcode cannot be the same as the current one');
        }
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: { passcode },
    });
  }
  async verifyPasscode(userId: string, passcode: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (!user.passcode) return true;
    return user.passcode === passcode;
  }
}
