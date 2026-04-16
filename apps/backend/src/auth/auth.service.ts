import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private emailService: EmailService,
    private jwtService: JwtService,
  ) {}

  async sendOtp(email: string) {
    // Check if user is whitelisted (added by admin)
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new UnauthorizedException('Access denied. Please contact admin.');
    }

    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    await this.prisma.otp.create({
      data: {
        email,
        code: otpCode,
        expiresAt,
      },
    });

    await this.emailService.sendOtp(email, otpCode);
    return { message: 'OTP sent to your email' };
  }

  async verifyOtp(email: string, code: string) {
    const otp = await this.prisma.otp.findFirst({
      where: {
        email,
        code,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otp) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    // Clean up used OTPs for this email
    await this.prisma.otp.deleteMany({ where: { email } });

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
        throw new UnauthorizedException('User not found');
    }
    
    return {
      access_token: this.jwtService.sign({ 
        sub: user.id, 
        email: user.email, 
        role: user.role 
      }),
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        balance: user.balance
      }
    };
  }
}
