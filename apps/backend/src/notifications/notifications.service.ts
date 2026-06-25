import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class NotificationsService {
  private firebaseApp: admin.app.App | null = null;

  constructor(private prisma: PrismaService) {
    this.initFirebase();
  }

  private initFirebase() {
    try {
      const individualProjectId = process.env.FIREBASE_PROJECT_ID;
      const individualClientEmail = process.env.FIREBASE_CLIENT_EMAIL;
      const individualPrivateKey = process.env.FIREBASE_PRIVATE_KEY;

      const envServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
      const envServiceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
      const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');

      const parseJsonConfig = (jsonStr: string) => {
        let clean = jsonStr.trim();
        // Remove outer quotes if Vercel/shell wrapped it
        if (clean.startsWith('"') && clean.endsWith('"')) {
          clean = clean.slice(1, -1);
        }
        // Unescape escaped quotes (e.g. \" to ")
        clean = clean.replace(/\\"/g, '"');
        
        try {
          const parsed = JSON.parse(clean);
          
          // Handle double-escaped newlines in private key AFTER parsing
          if (parsed && typeof parsed.private_key === 'string') {
            parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
          }
          
          return parsed;
        } catch (parseError) {
          console.warn('Standard JSON.parse failed. Attempting regex extraction fallback. Error:', parseError);
          
          // Regex fallback for malformed/escaped JSON strings
          const projectIdMatch = clean.match(/["']?project_id["']?\s*:\s*["']([^"']+)["']/);
          const clientEmailMatch = clean.match(/["']?client_email["']?\s*:\s*["']([^"']+)["']/);
          const privateKeyMatch = clean.match(/["']?private_key["']?\s*:\s*["']([^"']+)["']/);
          
          if (projectIdMatch && clientEmailMatch && privateKeyMatch) {
            const projectId = projectIdMatch[1];
            const clientEmail = clientEmailMatch[1];
            let privateKey = privateKeyMatch[1];
            
            // Clean up any escapes in private key (e.g. \n or \\n)
            privateKey = privateKey.replace(/\\n/g, '\n');
            
            console.log('Successfully extracted Firebase credentials via regex fallback.');
            return {
              projectId,
              clientEmail,
              privateKey,
            };
          }
          
          throw parseError;
        }
      };

      if (individualProjectId && individualClientEmail && individualPrivateKey) {
        const cleanKey = individualPrivateKey.replace(/\\n/g, '\n');
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert({
            projectId: individualProjectId,
            clientEmail: individualClientEmail,
            privateKey: cleanKey,
          }),
        });
        console.log('Firebase Admin initialized via individual environment variables.');
      } else if (envServiceAccount) {
        const parsedAccount = parseJsonConfig(envServiceAccount);
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(parsedAccount),
        });
        console.log('Firebase Admin initialized via FIREBASE_SERVICE_ACCOUNT env.');
      } else if (envServiceAccountBase64) {
        console.log(`Found FIREBASE_SERVICE_ACCOUNT_BASE64 env of length: ${envServiceAccountBase64.length}`);
        const decoded = Buffer.from(envServiceAccountBase64, 'base64').toString('utf-8');
        const parsedAccount = parseJsonConfig(decoded);
        console.log(`Decoded service account successfully. project_id is: "${parsedAccount?.project_id || parsedAccount?.project_info?.project_id || 'not found'}"`);
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(parsedAccount),
        });
        console.log('Firebase Admin initialized via FIREBASE_SERVICE_ACCOUNT_BASE64 env.');
      } else if (fs.existsSync(serviceAccountPath)) {
        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath),
        });
        console.log('Firebase Admin initialized via local JSON file.');
      } else {
        console.warn('Firebase Service Account not configured. Push notifications are disabled.');
      }
    } catch (error) {
      console.error('Failed to initialize Firebase Admin SDK:', error);
    }
  }

  async createNotification(
    userId: string,
    title: string,
    body: string,
    type: string,
    relatedId?: string,
  ) {
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        title,
        body,
        type,
        relatedId,
      },
    });

    await this.sendPushNotification(userId, title, body);

    return notification;
  }

  async notifyAdmins(title: string, body: string, type: string, relatedId?: string) {
    const admins = await this.prisma.user.findMany({
      where: { role: 'ADMIN' },
    });

    const notifications: any[] = [];
    for (const adminUser of admins) {
      const notification = await this.prisma.notification.create({
        data: {
          userId: adminUser.id,
          title,
          body,
          type,
          relatedId,
        },
      });
      notifications.push(notification);

      await this.sendPushNotification(adminUser.id, title, body);
    }

    return notifications;
  }

  async registerDeviceToken(userId: string, token: string, platform?: string) {
    return this.prisma.deviceToken.upsert({
      where: { token },
      update: { userId, platform },
      create: { userId, token, platform },
    });
  }

  async getNotifications(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markAsRead(notificationId: string, userId: string) {
    return this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true },
    });
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }

  private async sendPushNotification(userId: string, title: string, body: string) {
    const deviceTokens = await this.prisma.deviceToken.findMany({
      where: { userId },
    });

    if (deviceTokens.length === 0 || !this.firebaseApp) {
      return;
    }

    const tokens = deviceTokens.map((t) => t.token);

    const message = {
      notification: {
        title,
        body,
      },
      tokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Successfully sent push notifications: ${response.successCount} success, ${response.failureCount} failure.`);

      if (response.failureCount > 0) {
        for (let i = 0; i < response.responses.length; i++) {
          const resp = response.responses[i];
          if (!resp.success) {
            const error = resp.error;
            if (error?.code === 'messaging/invalid-registration-token' ||
                error?.code === 'messaging/registration-token-not-registered') {
              const invalidToken = tokens[i];
              await this.prisma.deviceToken.deleteMany({ where: { token: invalidToken } });
              console.log(`Removed stale/invalid device token: ${invalidToken}`);
            }
          }
        }
      }
    } catch (error) {
      console.error('Error sending multicast FCM push notification:', error);
    }
  }
}
