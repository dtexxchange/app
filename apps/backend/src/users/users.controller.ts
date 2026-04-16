import { Controller, Get, Post, Body, Param, UseGuards, Request, Query } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  async getMe(@Request() req) {
    return this.usersService.getMe(req.user.userId);
  }

  @Post()
  @Roles(Role.ADMIN)
  async create(@Body('email') email: string, @Body('role') role: Role) {
    return this.usersService.create(email, role);
  }

  @Get()
  @Roles(Role.ADMIN)
  async findAll(@Query('search') search?: string, @Query('role') role?: Role) {
    return this.usersService.findAll(search, role);
  }

  @Get(':id')
  @Roles(Role.ADMIN)
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }
}
