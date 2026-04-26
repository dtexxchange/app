import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { NewsService } from './news.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role, NewsStatus } from '@prisma/client';

@Controller('news')
export class NewsController {
  constructor(private newsService: NewsService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  async getPublishedNews() {
    return this.newsService.getPublishedNews();
  }

  @Get('admin')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async getAllNews() {
    return this.newsService.getAllNews();
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async createNews(
    @Body('title') title: string,
    @Body('description') description: string,
    @Body('link') link?: string,
  ) {
    return this.newsService.createNews(title, description, link);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async updateNews(
    @Param('id') id: string,
    @Body()
    data: {
      title?: string;
      description?: string;
      link?: string;
      status?: NewsStatus;
    },
  ) {
    return this.newsService.updateNews(id, data);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  async deleteNews(@Param('id') id: string) {
    return this.newsService.deleteNews(id);
  }
}
