import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { RateLimitService } from './rate-limit.service';
import { UserProfile } from '../auth/entities/user-profile.entity';
import Redis from 'ioredis';
import { REDIS_CLIENT } from './constants';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([UserProfile])],
  providers: [
    {
      provide: REDIS_CLIENT,
      useFactory: (configService: ConfigService) => {
        return new Redis({
          host: configService.get('REDIS_HOST', '192.168.50.201'),
          port: configService.get<number>('REDIS_PORT', 6379),
          password: configService.get('REDIS_PASSWORD'),
          keyPrefix: 'dm:',
        });
      },
      inject: [ConfigService],
    },
    RateLimitService,
  ],
  exports: [REDIS_CLIENT, RateLimitService],
})
export class RateLimitModule {}
