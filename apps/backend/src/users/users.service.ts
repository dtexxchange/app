import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Role } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async create(email: string, role: Role = Role.USER) {
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('User already exists');

    return this.prisma.user.create({
      data: { email, role },
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
