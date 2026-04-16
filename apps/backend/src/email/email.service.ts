import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private resend: Resend;

  constructor(private configService: ConfigService) {
    this.resend = new Resend(this.configService.get<string>('RESEND_API_KEY'));
  }

  async sendOtp(email: string, otp: string) {
    try {
      await this.resend.emails.send({
        from: 'no-reply@trekora.arstyn.com',
        to: email,
        subject: 'Your OTP for USDT Exchange',
        html: `<p>Your OTP is: <strong>${otp}</strong>. It expires in 10 minutes.</p>`,
      });
    } catch (error) {
      console.error('Failed to send email:', error);
      throw new Error('Could not send OTP email');
    }
  }
}
