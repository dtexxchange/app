import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private resend: Resend;
  private readonly BRAND_COLOR = '#00FF9D';
  private readonly DARK_BG = '#0A0B0D';
  private readonly PANEL_BG = '#15171C';
  private readonly TEXT_DIM = '#94A3B8';

  constructor(private configService: ConfigService) {
    this.resend = new Resend(this.configService.get<string>('RESEND_API_KEY'));
  }

  private getEmailWrapper(content: string, title: string) {
    return `
      <div style="background-color: ${this.DARK_BG}; color: #ffffff; font-family: 'Inter', sans-serif; padding: 40px 20px; text-align: center;">
        <div style="max-width: 500px; margin: 0 auto; background-color: ${this.PANEL_BG}; border: 1px solid rgba(255, 255, 255, 0.05); border-radius: 24px; padding: 40px; box-shadow: 0 20px 40px rgba(0,0,0,0.4);">
          <div style="margin-bottom: 30px;">
            <div style="width: 64px; height: 64px; background-color: rgba(0, 255, 157, 0.1); border-radius: 16px; margin: 0 auto; display: flex; align-items: center; justify-content: center;">
               <span style="font-size: 32px; color: ${this.BRAND_COLOR};">✦</span>
            </div>
          </div>
          <h1 style="color: #ffffff; font-size: 24px; font-weight: 700; margin-bottom: 10px;">${title}</h1>
          <div style="width: 40px; height: 2px; background-color: ${this.BRAND_COLOR}; margin: 0 auto 30px auto;"></div>
          ${content}
          <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid rgba(255, 255, 255, 0.05);">
            <p style="color: ${this.TEXT_DIM}; font-size: 12px; margin-bottom: 0;">Protected by DtExxchange Workspace security.</p>
          </div>
        </div>
      </div>
    `;
  }

  async sendOtp(email: string, otp: string) {
    const html = this.getEmailWrapper(
      `
      <p style="color: ${this.TEXT_DIM}; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Use the following authorization code to access your workspace. This code is valid for 10 minutes.
      </p>
      <div style="background-color: rgba(255, 255, 255, 0.03); border: 1px solid rgba(0, 255, 157, 0.2); border-radius: 12px; padding: 24px; margin-bottom: 30px;">
        <span style="color: ${this.BRAND_COLOR}; font-family: monospace; font-size: 36px; font-weight: 700; letter-spacing: 12px; margin-left: 12px;">${otp}</span>
      </div>
      <p style="color: ${this.TEXT_DIM}; font-size: 14px;">If you didn't request this, you can safely ignore this email.</p>
    `,
      'Authorize Access',
    );

    try {
      await this.resend.emails.send({
        from: 'no-reply@trekora.arstyn.com',
        to: email,
        subject: 'Authorization Code - DtExxchange',
        html,
      });
    } catch (error) {
      console.error('Failed to send OTP email:', error);
      throw new Error('Could not send OTP email');
    }
  }

  async sendApprovalEmail(email: string, userName: string) {
    const html = this.getEmailWrapper(
      `
      <p style="color: ${this.TEXT_DIM}; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Hello ${userName}, we're excited to inform you that your registration request has been <strong>approved</strong> by our administration.
      </p>
      <p style="color: ${this.TEXT_DIM}; font-size: 16px; line-height: 1.6; margin-bottom: 40px;">
        You can now sign in to your workspace and start managing your assets seamlessly.
      </p>
      <a href="https://dtexxchange.netlify.app/login" style="display: inline-block; background-color: ${this.BRAND_COLOR}; color: #000000; padding: 16px 40px; border-radius: 12px; font-weight: 700; text-decoration: none; font-size: 15px;">Launch Workspace</a>
    `,
      'Identity Verified',
    );

    try {
      await this.resend.emails.send({
        from: 'no-reply@trekora.arstyn.com',
        to: email,
        subject: 'Welcome to dtexxchange - Identity Verified',
        html,
      });
    } catch (error) {
      console.error('Failed to send approval email:', error);
    }
  }
  async sendAssignmentAlert(
    adminEmail: string,
    userEmail: string,
    walletAddress: string,
    walletName: string,
  ) {
    const html = this.getEmailWrapper(
      `
      <p style="color: ${this.TEXT_DIM}; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        A user has just viewed a deposit QR code. You can use this information to match incoming transfers.
      </p>
      <div style="background-color: rgba(255, 255, 255, 0.03); border: 1px solid rgba(0, 255, 157, 0.1); border-radius: 16px; padding: 24px; text-align: left; margin-bottom: 30px;">
        <div style="margin-bottom: 16px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">User</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">${userEmail}</p>
        </div>
        <div style="margin-bottom: 16px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Wallet Gateway</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">${walletName}</p>
        </div>
        <div>
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Address</p>
          <code style="color: ${this.BRAND_COLOR}; font-size: 12px; font-family: monospace;">${walletAddress}</code>
        </div>
      </div>
      <p style="color: ${this.TEXT_DIM}; font-size: 14px;">The assignment is valid for the next 30 minutes.</p>
    `,
      'Deposit Intent Detected',
    );

    try {
      await this.resend.emails.send({
        from: 'no-reply@trekora.arstyn.com',
        to: adminEmail,
        subject: `[Alert] Deposit QR Viewed - ${userEmail}`,
        html,
      });
    } catch (error) {
      console.error('Failed to send assignment alert email:', error);
    }
  }
}
