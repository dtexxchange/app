import {
  Body,
  Controller,
  Get,
  Logger,
  NotFoundException,
  Param,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Role } from '@prisma/client';
import type { Response } from 'express';
import * as fs from 'fs';
import { diskStorage } from 'multer';
import * as path from 'path';
import { extname } from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { AppReleaseService } from './app-release.service';

@Controller('app-releases')
export class AppReleaseController {
  private readonly logger = new Logger(AppReleaseController.name);

  constructor(private readonly appReleaseService: AppReleaseService) {}

  @Get('latest')
  async getLatestRelease() {
    return this.appReleaseService.getLatestRelease();
  }

  @Get()
  async getAllReleases() {
    return this.appReleaseService.getAllReleases();
  }

  @Get('download-latest')
  async downloadLatest(@Res() res: Response) {
    this.logger.log('[APK Download] Received request for latest release APK');
    const latest = await this.appReleaseService.getLatestRelease();
    if (!latest || !latest.apkUrl) {
      this.logger.warn('[APK Download] No active release found in database');
      throw new NotFoundException('No active release found.');
    }
    const filename = path.basename(latest.apkUrl);
    return this.downloadFile(filename, res);
  }

  @Get('download/:filename')
  async downloadFile(
    @Param('filename') filename: string,
    @Res() res: Response,
  ) {
    const cleanFilename = path.basename(filename);
    const candidatePaths = [
      path.join(process.cwd(), 'public', 'apks', cleanFilename),
      path.join(process.cwd(), 'public', cleanFilename),
      path.join(__dirname, '..', '..', 'public', 'apks', cleanFilename),
      path.join(__dirname, '..', '..', 'public', cleanFilename),
      path.join(__dirname, '..', 'public', 'apks', cleanFilename),
      path.join('/tmp', cleanFilename),
    ];

    this.logger.log(`[APK Download] Locating APK file: ${cleanFilename}`);
    let targetPath: string | null = null;
    for (const p of candidatePaths) {
      if (fs.existsSync(p)) {
        targetPath = p;
        break;
      }
    }

    if (!targetPath) {
      this.logger.error(
        `[APK Download] File not found: ${cleanFilename}. Searched paths: ${candidatePaths.join(', ')}`,
      );
      throw new NotFoundException(`File ${cleanFilename} was not found on the server.`);
    }

    this.logger.log(`[APK Download] Serving ${cleanFilename} from ${targetPath}`);
    res.setHeader('Content-Type', 'application/vnd.android.package-archive');
    res.setHeader('Content-Disposition', `attachment; filename="${cleanFilename}"`);
    res.setHeader('Cache-Control', 'public, max-age=3600');
    return res.sendFile(path.resolve(targetPath));
  }

  @Get('apks/:filename')
  async getApkAlias(
    @Param('filename') filename: string,
    @Res() res: Response,
  ) {
    return this.downloadFile(filename, res);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (req, file, cb) => {
          const dir = './public/apks';
          try {
            if (!fs.existsSync(dir)) {
              fs.mkdirSync(dir, { recursive: true });
            }
            cb(null, dir);
          } catch (err) {
            // Fallback to /tmp for read-only environments
            cb(null, '/tmp');
          }
        },
        filename: (req, file, cb) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          cb(null, `app-${uniqueSuffix}${ext}`);
        },
      }),
    }),
  )
  async createRelease(
    @UploadedFile() file: Express.Multer.File,
    @Body('version') version: string,
    @Body('changes') changes: string,
  ) {
    if (!file) {
      throw new Error('File is required');
    }
    this.logger.log(
      `[APK Upload] New release uploaded: version=${version}, filename=${file.filename}, size=${file.size} bytes`,
    );
    const apkUrl = `/apks/${file.filename}`;
    return this.appReleaseService.createRelease(version, changes, apkUrl, file.path);
  }
}
