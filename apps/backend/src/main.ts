import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';
import { TransactionType } from '@prisma/client';

(BigInt.prototype as any).toJSON = function () {
  return this.toString().padStart(12, '0');
};

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
  }));

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Application is running on: http://localhost:${port}`);

  // One-time migration for old referral logs
  const prisma = app.get(PrismaService);
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
bootstrap();
