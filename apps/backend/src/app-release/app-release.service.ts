import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class AppReleaseService {
  constructor(private prisma: PrismaService) {}

  async getLatestRelease() {
    return this.prisma.appRelease.findFirst({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAllReleases() {
    return this.prisma.appRelease.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async createRelease(version: string, changes: string, apkUrl: string, filePath: string) {
    // 1. Deactivate all existing releases
    await this.prisma.appRelease.updateMany({
      where: { isActive: true },
      data: { isActive: false },
    });

    // 2. Delete the old APK files to save space
    const oldReleases = await this.prisma.appRelease.findMany({
      where: { apkUrl: { not: null } },
    });

    for (const release of oldReleases) {
      if (release.apkUrl) {
        // apkUrl is something like /apks/app-12345.apk
        const oldFilePath = path.join(process.cwd(), 'public', release.apkUrl);
        if (fs.existsSync(oldFilePath)) {
          try {
            fs.unlinkSync(oldFilePath);
          } catch (e) {
            console.error('Failed to delete old APK file', e);
          }
        }
      }
    }

    // Nullify all old apkUrls in the database
    await this.prisma.appRelease.updateMany({
      where: { apkUrl: { not: null } },
      data: { apkUrl: null },
    });

    // 3. Create the new release
    return this.prisma.appRelease.create({
      data: {
        version,
        changes,
        apkUrl,
        isActive: true,
      },
    });
  }
}
