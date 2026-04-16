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
}
