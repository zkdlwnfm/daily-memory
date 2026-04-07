import { Controller, Get, Post, Param, Query, Headers, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags } from '@nestjs/swagger';
import { AdminService } from './admin.service';

@ApiTags('Admin')
@Controller('admin')
export class AdminController {
  private readonly adminKey: string;

  constructor(
    private readonly adminService: AdminService,
    private configService: ConfigService,
  ) {
    this.adminKey = this.configService.get('ADMIN_KEY', 'engram-admin-2026');
  }

  private checkAuth(authHeader?: string) {
    const key = authHeader?.replace('Bearer ', '');
    if (key !== this.adminKey) {
      throw new UnauthorizedException('Invalid admin key');
    }
  }

  @Get('stats')
  async getStats(@Headers('authorization') auth: string) {
    this.checkAuth(auth);
    return this.adminService.getStats();
  }

  @Get('usage')
  async getUsage(
    @Headers('authorization') auth: string,
    @Query('days') days?: string,
  ) {
    this.checkAuth(auth);
    return this.adminService.getUsage(days ? parseInt(days) : 7);
  }

  @Get('users')
  async getUsers(@Headers('authorization') auth: string) {
    this.checkAuth(auth);
    return this.adminService.getUsers();
  }

  @Get('rate-limits')
  async getRateLimits(@Headers('authorization') auth: string) {
    this.checkAuth(auth);
    return this.adminService.getRateLimits();
  }

  @Post('users/:uid/toggle-premium')
  async togglePremium(
    @Headers('authorization') auth: string,
    @Param('uid') uid: string,
  ) {
    this.checkAuth(auth);
    const isPremium = await this.adminService.togglePremium(uid);
    return { uid, isPremium };
  }
}
