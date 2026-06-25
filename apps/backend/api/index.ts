import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { ExpressAdapter } from '@nestjs/platform-express';
import { ValidationPipe } from '@nestjs/common';
import { PrismaService } from '../src/prisma/prisma.service';
import express from 'express';
import type { VercelRequest, VercelResponse } from '@vercel/node';

const expressApp = express();
let nestApp: any;

async function bootstrap() {
  if (!nestApp) {
    nestApp = await NestFactory.create(
      AppModule,
      new ExpressAdapter(expressApp),
    );

    nestApp.enableCors();
    nestApp.useGlobalPipes(new ValidationPipe({
      whitelist: true,
      transform: true,
    }));

    (BigInt.prototype as any).toJSON = function () {
      return this.toString().padStart(12, '0');
    };

    await nestApp.init();

    // One-time migration for old referral logs
    const prisma = nestApp.get(PrismaService);
    try {
      const logs = await prisma.transactionLog.findMany({
        where: {
          transaction: { type: 'REFERRAL_COMMISSION' as any },
          note: { contains: '@' }
        }
      });

      if (logs.length > 0) {
        console.log(`Migrating ${logs.length} referral logs...`);
        for (const log of logs) {
          if (!log.note) continue;
          const emailMatch = log.note.match(/[a-zA-Z0-9._%+-]+@[\w.-]+\.[a-zA-Z]{2,}/);
          if (emailMatch) {
            const email = emailMatch[0];
            const user = await prisma.user.findUnique({ where: { email } });
            if (user) {
              const name = (user.firstName || user.lastName)
                ? `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim()
                : email;
              await prisma.transactionLog.update({
                where: { id: log.id },
                data: { note: log.note.replace(email, name) }
              });
            }
          }
        }
        console.log('Referral log migration completed.');
      }
    } catch (e) {
      console.error('Referral migration failed:', e);
    }
  }
  return expressApp;
}

export default async (req: VercelRequest, res: VercelResponse) => {
  await bootstrap();
  expressApp(req, res);
};
