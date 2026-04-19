import { Injectable, UnauthorizedException } from '@nestjs/common';
import { User } from '@prisma/client';
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
    const normalizedEmail = email.toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (!user) {
      throw new UnauthorizedException('Access denied. Please signup first.');
    }

    if (user.status === 'REJECTED') {
      throw new UnauthorizedException('Your account has been rejected.');
    }

    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    await this.prisma.otp.create({
      data: {
        email: normalizedEmail,
        code: otpCode,
        expiresAt,
      },
    });

    await this.emailService.sendOtp(normalizedEmail, otpCode);
    return { message: 'OTP sent to your email' };
  }

  async signup(email: string, firstName: string, lastName: string, referralCode?: string) {
    const normalizedEmail = email.toLowerCase();
    const existingUser = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (existingUser) {
      throw new UnauthorizedException('Email already registered. Please login.');
    }

    let referredBy: User | null = null;
    if (referralCode) {
      referredBy = await this.prisma.user.findUnique({
        where: { referralCode },
      });
      if (!referredBy) {
        throw new UnauthorizedException('Invalid referral code.');
      }
    }

    const userReferralCode = Math.random().toString(36).substring(2, 10).toUpperCase();

    await this.prisma.user.create({
      data: {
        email: normalizedEmail,
        firstName,
        lastName,
        status: 'PENDING_APPROVAL',
        referralCode: userReferralCode,
        referredById: referredBy?.id,
      },
    });

    return { message: 'Account created. Please wait for admin approval.' };
  }

  async verifyOtp(email: string, code: string) {
    const normalizedEmail = email.toLowerCase();
    const otp = await this.prisma.otp.findFirst({
      where: {
        email: normalizedEmail,
        code,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otp) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    // Clean up used OTPs for this email
    await this.prisma.otp.deleteMany({ where: { email: normalizedEmail } });

    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    if (user.status === 'PENDING_APPROVAL') {
      throw new UnauthorizedException('Verification is under processing. Please check your email for status updates.');
    }

    if (user.status === 'REJECTED') {
      throw new UnauthorizedException('Your account has been rejected.');
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
