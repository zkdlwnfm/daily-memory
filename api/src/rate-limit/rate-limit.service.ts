import { Injectable, Inject } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import Redis from 'ioredis';
import { ConfigService } from '@nestjs/config';
import { REDIS_CLIENT } from './constants';
import { UserProfile } from '../auth/entities/user-profile.entity';

export type EndpointType = 'ai' | 'image' | 'embed' | 'search';

@Injectable()
export class RateLimitService {
  private limits: Record<EndpointType, { free: number; premium: number }>;

  constructor(
    @Inject(REDIS_CLIENT) private redis: Redis,
    @InjectRepository(UserProfile)
    private userProfileRepo: Repository<UserProfile>,
    private configService: ConfigService,
  ) {
    this.limits = {
      ai: {
        free: this.configService.get<number>('RATE_LIMIT_FREE_AI', 30),
        premium: this.configService.get<number>('RATE_LIMIT_PREMIUM_AI', 200),
      },
      image: {
        free: this.configService.get<number>('RATE_LIMIT_FREE_IMAGE', 10),
        premium: this.configService.get<number>('RATE_LIMIT_PREMIUM_IMAGE', 100),
      },
      embed: {
        free: this.configService.get<number>('RATE_LIMIT_FREE_EMBED', 50),
        premium: this.configService.get<number>('RATE_LIMIT_PREMIUM_EMBED', 500),
      },
      search: {
        free: this.configService.get<number>('RATE_LIMIT_FREE_SEARCH', 50),
        premium: this.configService.get<number>('RATE_LIMIT_PREMIUM_SEARCH', 500),
      },
    };
  }

  async checkAndIncrement(userId: string, endpoint: EndpointType): Promise<{ allowed: boolean; remaining: number; limit: number }> {
    const profile = await this.userProfileRepo.findOne({ where: { firebaseUid: userId } });
    const isPremium = profile?.isPremium || false;
    const limit = isPremium ? this.limits[endpoint].premium : this.limits[endpoint].free;

    const today = new Date().toISOString().split('T')[0];
    const key = `ratelimit:${userId}:${endpoint}:${today}`;

    const current = await this.redis.incr(key);

    // Set TTL on first use (expire at end of day)
    if (current === 1) {
      await this.redis.expire(key, 86400);
    }

    const allowed = current <= limit;
    const remaining = Math.max(0, limit - current);

    return { allowed, remaining, limit };
  }

  async getRemainingQuotas(userId: string): Promise<Record<EndpointType, { remaining: number; limit: number }>> {
    const profile = await this.userProfileRepo.findOne({ where: { firebaseUid: userId } });
    const isPremium = profile?.isPremium || false;
    const today = new Date().toISOString().split('T')[0];

    const result = {} as Record<EndpointType, { remaining: number; limit: number }>;

    for (const endpoint of ['ai', 'image', 'embed', 'search'] as EndpointType[]) {
      const limit = isPremium ? this.limits[endpoint].premium : this.limits[endpoint].free;
      const key = `ratelimit:${userId}:${endpoint}:${today}`;
      const current = parseInt(await this.redis.get(key) || '0', 10);
      result[endpoint] = { remaining: Math.max(0, limit - current), limit };
    }

    return result;
  }
}
