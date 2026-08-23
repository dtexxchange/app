import { Body, Controller, Get, Post, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Role } from '@prisma/client';
import * as fs from 'fs';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { AppReleaseService } from './app-release.service';

@Controller('app-releases')
export class AppReleaseController {
  constructor(private readonly appReleaseService: AppReleaseService) { }

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
      destination: (req, file, cb) => {
        const dir = './public/apks';
        try {
          if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
          }
          cb(null, dir);
        } catch (err) {
          // Fallback to /tmp for read-only environments like Vercel
          cb(null, '/tmp');
        }
      },
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
