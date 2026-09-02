import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { BankAccountsModule } from './bank-accounts/bank-accounts.module';
import { EmailModule } from './email/email.module';
import { PrismaModule } from './prisma/prisma.module';
import { SettingsModule } from './settings/settings.module';
import { UsersModule } from './users/users.module';
import { WalletModule } from './wallet/wallet.module';
import { NotificationsModule } from './notifications/notifications.module';
import { NewsModule } from './news/news.module';
import { TicketsModule } from './tickets/tickets.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AppReleaseModule } from './app-release/app-release.module';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ServeStaticModule.forRoot(
      {
        rootPath: join(process.cwd(), 'public'),
        serveRoot: '/',
        serveStaticOptions: { index: false },
      },
      {
        rootPath: join(process.cwd(), 'public'),
        serveRoot: '/api',
        serveStaticOptions: { index: false },
      },
    ),
    PrismaModule,
    EmailModule,
    AuthModule,
    UsersModule,
    WalletModule,
    SettingsModule,
    BankAccountsModule,
    NotificationsModule,
    NewsModule,
    TicketsModule,
    AppReleaseModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
