import { Module } from '@nestjs/common';
import { AppReleaseService } from './app-release.service';
import { AppReleaseController } from './app-release.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AppReleaseController],
  providers: [AppReleaseService],
})
export class AppReleaseModule {}
