import { Controller, Get, Logger, NotFoundException, Param, Res } from '@nestjs/common';
import type { Response } from 'express';
import * as fs from 'fs';
import * as path from 'path';
import { AppService } from './app.service';

@Controller()
export class AppController {
  private readonly logger = new Logger(AppController.name);

  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('apks/:filename')
  getApk(@Param('filename') filename: string, @Res() res: Response) {
    const cleanFilename = path.basename(filename);
    const candidatePaths = [
      path.join(process.cwd(), 'public', 'apks', cleanFilename),
      path.join(process.cwd(), 'public', cleanFilename),
      path.join(__dirname, '..', '..', 'public', 'apks', cleanFilename),
      path.join(__dirname, '..', '..', 'public', cleanFilename),
      path.join(__dirname, '..', 'public', 'apks', cleanFilename),
      path.join('/tmp', cleanFilename),
    ];

    let targetPath: string | null = null;
    for (const p of candidatePaths) {
      if (fs.existsSync(p)) {
        targetPath = p;
        break;
      }
    }

    if (!targetPath) {
      this.logger.error(`APK not found: ${cleanFilename}`);
      throw new NotFoundException(`File ${cleanFilename} was not found on the server.`);
    }

    this.logger.log(`Serving APK from ${targetPath}`);
    res.setHeader('Content-Type', 'application/vnd.android.package-archive');
    res.setHeader('Content-Disposition', `attachment; filename="${cleanFilename}"`);
    res.setHeader('Cache-Control', 'public, max-age=3600');
    return res.sendFile(path.resolve(targetPath));
  }
}
