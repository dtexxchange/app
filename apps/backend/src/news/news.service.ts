import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NewsStatus } from '@prisma/client';

@Injectable()
export class NewsService {
  constructor(private prisma: PrismaService) {}

  async createNews(title: string, description: string, link?: string) {
    return this.prisma.news.create({
      data: {
        title,
        description,
        link,
      },
    });
  }

  async getAllNews() {
    return this.prisma.news.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPublishedNews() {
    return this.prisma.news.findMany({
      where: { status: NewsStatus.PUBLISHED },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateNews(id: string, data: { title?: string; description?: string; link?: string; status?: NewsStatus }) {
    return this.prisma.news.update({
      where: { id },
      data,
    });
  }

  async deleteNews(id: string) {
    return this.prisma.news.delete({
      where: { id },
    });
  }
}
