import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: Transporter;
  private fromEmail: string;
  private appName: string;
  private appUrl: string;
  private readonly BRAND_COLOR = '#00FF9D';
  private readonly DARK_BG = '#0A0B0D';
  private readonly PANEL_BG = '#15171C';
  private readonly TEXT_DIM = '#94A3B8';

  constructor(private configService: ConfigService) {
    const host = this.configService.get<string>('SMTP_HOST', 'cp3.offsh.nl');
    const port = Number(this.configService.get<number | string>('SMTP_PORT', 465));
    const secure =
      this.configService.get<string | boolean>('SMTP_SECURE', true) === true ||
      this.configService.get<string | boolean>('SMTP_SECURE') === 'true' ||
      port === 465;
    const user = this.configService.get<string>(
      'SMTP_USER',
      'no-reply@equinoxexchange.cc',
    );
    const pass = this.configService.get<string>('SMTP_PASS', '');

    this.appName = this.configService.get<string>('APP_NAME', 'Equinox Exchange');
    this.appUrl = this.configService.get<string>(
      'APP_URL',
      'https://equinoxexchange.cc',
    );

    const defaultFrom = `"${this.appName}" <${user}>`;
    this.fromEmail = this.configService.get<string>('SMTP_FROM', defaultFrom);

    this.transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      auth: {
        user,
        pass,
      },
    });
  }

  private async sendMail(options: { to: string; subject: string; html: string }) {
    return this.transporter.sendMail({
      from: this.fromEmail,
      to: options.to,
      subject: options.subject,
      html: options.html,
    });
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
            <p style="color: ${this.TEXT_DIM}; font-size: 12px; margin-bottom: 0;">Protected by ${this.appName} Workspace security.</p>
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
      await this.sendMail({
        to: email,
        subject: `Authorization Code - ${this.appName}`,
        html,
      });
    } catch (error) {
      this.logger.error('Failed to send OTP email:', error);
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
      <a href="${this.appUrl}/login" style="display: inline-block; background-color: ${this.BRAND_COLOR}; color: #000000; padding: 16px 40px; border-radius: 12px; font-weight: 700; text-decoration: none; font-size: 15px;">Launch Workspace</a>
    `,
      'Identity Verified',
    );

    try {
      await this.sendMail({
        to: email,
        subject: `Welcome to ${this.appName} - Identity Verified`,
        html,
      });
    } catch (error) {
      this.logger.error('Failed to send approval email:', error);
    }
  }

  async sendAssignmentAlert(
    adminEmail: string,
    userName: string,
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
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">${userName}</p>
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
      await this.sendMail({
        to: adminEmail,
        subject: `[Alert] Deposit QR Viewed - ${userName}`,
        html,
      });
    } catch (error) {
      this.logger.error('Failed to send assignment alert email:', error);
    }
  }

  async sendTicketCreatedAdminAlert(
    adminEmail: string,
    readableId: string,
    subject: string,
    userEmail: string,
    description: string,
  ) {
    const html = this.getEmailWrapper(
      `
      <p style="color: ${this.TEXT_DIM}; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        A new help & support ticket has been raised by a user.
      </p>
      <div style="background-color: rgba(255, 255, 255, 0.03); border: 1px solid rgba(0, 255, 157, 0.1); border-radius: 16px; padding: 24px; text-align: left; margin-bottom: 30px;">
        <div style="margin-bottom: 16px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Ticket ID</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">#${readableId}</p>
        </div>
        <div style="margin-bottom: 16px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">User Email</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">${userEmail}</p>
        </div>
        <div style="margin-bottom: 16px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Subject</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">${subject}</p>
        </div>
        <div>
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Description</p>
          <p style="color: ${this.TEXT_DIM}; font-size: 14px; margin: 0; line-height: 1.4;">${description}</p>
        </div>
      </div>
    `,
      'New Ticket Raised',
    );

    try {
      await this.sendMail({
        to: adminEmail,
        subject: `[Support Ticket #${readableId}] ${subject}`,
        html,
      });
    } catch (error) {
      this.logger.error('Failed to send ticket created admin email:', error);
    }
  }

  async sendTicketReplyAlert(
    toEmail: string,
    senderEmail: string,
    readableId: string,
    subject: string,
    messageContent: string,
    isToAdmin: boolean,
  ) {
    const title = isToAdmin ? 'New Ticket Reply' : 'Admin Ticket Reply';
    const heading = isToAdmin
      ? `A user has replied to Ticket #${readableId}`
      : `An administrator has replied to your Ticket #${readableId}`;

    const html = this.getEmailWrapper(
      `
      <p style="color: ${this.TEXT_DIM}; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        ${heading}
      </p>
      <div style="background-color: rgba(255, 255, 255, 0.03); border: 1px solid rgba(0, 255, 157, 0.1); border-radius: 16px; padding: 24px; text-align: left; margin-bottom: 30px;">
        <div style="margin-bottom: 12px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Sender</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">${senderEmail}</p>
        </div>
        <div style="margin-bottom: 12px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Ticket</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">#${readableId} - ${subject}</p>
        </div>
        <div>
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Message</p>
          <p style="color: #ffffff; font-size: 14px; margin: 0; line-height: 1.4;">${messageContent}</p>
        </div>
      </div>
    `,
      title,
    );

    try {
      await this.sendMail({
        to: toEmail,
        subject: `[Re: Ticket #${readableId}] ${subject}`,
        html,
      });
    } catch (error) {
      this.logger.error('Failed to send ticket reply email:', error);
    }
  }

  async sendTicketStatusAlert(
    userEmail: string,
    readableId: string,
    subject: string,
    status: string,
  ) {
    const formattedStatus = status.replace(/_/g, ' ');
    const html = this.getEmailWrapper(
      `
      <p style="color: ${this.TEXT_DIM}; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Your support ticket has been updated by an administrator.
      </p>
      <div style="background-color: rgba(255, 255, 255, 0.03); border: 1px solid rgba(0, 255, 157, 0.1); border-radius: 16px; padding: 24px; text-align: left; margin-bottom: 30px;">
        <div style="margin-bottom: 16px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Ticket ID</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">#${readableId}</p>
        </div>
        <div style="margin-bottom: 16px;">
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">Subject</p>
          <p style="color: #ffffff; font-size: 14px; font-weight: 600; margin: 0;">${subject}</p>
        </div>
        <div>
          <p style="color: ${this.TEXT_DIM}; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 4px;">New Status</p>
          <p style="color: ${this.BRAND_COLOR}; font-size: 18px; font-weight: 700; margin: 0;">${formattedStatus}</p>
        </div>
      </div>
    `,
      'Ticket Status Updated',
    );

    try {
      await this.sendMail({
        to: userEmail,
        subject: `[Status Update: Ticket #${readableId}] ${subject}`,
        html,
      });
    } catch (error) {
      this.logger.error('Failed to send ticket status email:', error);
    }
  }
}
