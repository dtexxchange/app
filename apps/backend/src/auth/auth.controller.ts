import { Controller, Post, Body, ForbiddenException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { Role } from '@prisma/client';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private prisma: PrismaService
  ) {}

  @Post('setup-admin')
  async setupAdmin(@Body('email') email: string) {
    const userCount = await this.prisma.user.count();
    if (userCount > 0) {
      throw new ForbiddenException('Admin already setup');
    }
    return this.prisma.user.create({
      data: {
        email,
        role: Role.ADMIN
      }
    });
  }

  @Post('send-otp')
  async sendOtp(@Body('email') email: string) {
    return this.authService.sendOtp(email);
  }

  @Post('verify-otp')
  async verifyOtp(@Body('email') email: string, @Body('code') code: string) {
    return this.authService.verifyOtp(email, code);
  }
}
