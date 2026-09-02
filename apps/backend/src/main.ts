import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { PrismaService } from './prisma/prisma.service';

(BigInt.prototype as any).toJSON = function () {
  return this.toString().padStart(12, '0');
};

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const httpLogger = new Logger('HTTP');

  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });

  // Global HTTP Request Logger middleware for PM2 / Console observability
  app.use((req: any, res: any, next: any) => {
    const { method, originalUrl } = req;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '';
    const start = Date.now();

    res.on('finish', () => {
      const { statusCode } = res;
      const duration = Date.now() - start;
      const logMessage = `${method} ${originalUrl} ${statusCode} - ${duration}ms [${ip}]`;
      if (statusCode >= 500) {
        httpLogger.error(logMessage);
      } else if (statusCode >= 400) {
        httpLogger.warn(logMessage);
      } else {
        httpLogger.log(logMessage);
      }
    });

    next();
  });

  app.setGlobalPrefix('api');
  app.enableCors();
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);
  logger.log(`Application is running on: http://localhost:${port}/api`);

  // Global process-level exception logging for PM2
  process.on('unhandledRejection', (reason: any) => {
    logger.error('Unhandled Rejection at Promise:', reason?.stack || reason);
  });
  process.on('uncaughtException', (err: any) => {
    logger.error('Uncaught Exception thrown:', err?.stack || err);
  });

  // One-time migration for old referral logs
  const prisma = app.get(PrismaService);
  try {
    const logs = await prisma.transactionLog.findMany({
      where: {
        transaction: { type: 'REFERRAL_COMMISSION' as any },
        note: { contains: '@' },
      },
    });

    if (logs.length > 0) {
      logger.log(`Migrating ${logs.length} referral logs...`);
      for (const log of logs) {
        if (!log.note) continue;
        const emailMatch = log.note.match(
          /[a-zA-Z0-9._%+-]+@[\w.-]+\.[a-zA-Z]{2,}/,
        );
        if (emailMatch) {
          const email = emailMatch[0];
          const user = await prisma.user.findUnique({ where: { email } });
          if (user) {
            const name =
              user.firstName || user.lastName
                ? `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim()
                : email;
            await prisma.transactionLog.update({
              where: { id: log.id },
              data: { note: log.note.replace(email, name) },
            });
          }
        }
      }
      logger.log('Referral log migration completed.');
    }
  } catch (e) {
    logger.error('Referral migration failed:', e);
  }
}
bootstrap();
