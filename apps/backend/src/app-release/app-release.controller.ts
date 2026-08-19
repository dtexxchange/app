import { Controller, Get, Post, Body, UseInterceptors, UploadedFile, UseGuards } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AppReleaseService } from './app-release.service';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('app-releases')
export class AppReleaseController {
  constructor(private readonly appReleaseService: AppReleaseService) {}

  @Get('latest')
  async getLatestRelease() {
    return this.appReleaseService.getLatestRelease();
  }

  @Get()
  async getAllReleases() {
    return this.appReleaseService.getAllReleases();
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './public/apks',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = extname(file.originalname);
        cb(null, `app-${uniqueSuffix}${ext}`);
      }
    })
  }))
  async createRelease(
    @UploadedFile() file: Express.Multer.File,
    @Body('version') version: string,
    @Body('changes') changes: string,
  ) {
    if (!file) {
      throw new Error('File is required');
    }
    const apkUrl = `/apks/${file.filename}`;
    return this.appReleaseService.createRelease(version, changes, apkUrl, file.path);
  }
}
