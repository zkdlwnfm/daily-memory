import { Injectable, Inject } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import Redis from 'ioredis';
import { UserProfile } from '../auth/entities/user-profile.entity';
import { ApiUsageLog } from '../common/entities/api-usage-log.entity';
import { MemoryEmbedding } from '../search/entities/memory-embedding.entity';
import { REDIS_CLIENT } from '../rate-limit/constants';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(UserProfile) private userRepo: Repository<UserProfile>,
    @InjectRepository(ApiUsageLog) private usageRepo: Repository<ApiUsageLog>,
    @InjectRepository(MemoryEmbedding) private embeddingRepo: Repository<MemoryEmbedding>,
    @Inject(REDIS_CLIENT) private redis: Redis,
    private dataSource: DataSource,
  ) {}

  async getStats() {
    const totalUsers = await this.userRepo.count();
    const premiumUsers = await this.userRepo.count({ where: { isPremium: true } });
    const totalEmbeddings = await this.embeddingRepo.count();

    // Today's stats
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todayLogs = await this.usageRepo
      .createQueryBuilder('log')
      .where('log.created_at >= :today', { today })
      .getCount();

    const todaySuccessful = await this.usageRepo
      .createQueryBuilder('log')
      .where('log.created_at >= :today', { today })
      .andWhere('log.status = :status', { status: 'success' })
      .getCount();

    const todayErrors = await this.usageRepo
      .createQueryBuilder('log')
      .where('log.created_at >= :today', { today })
      .andWhere('log.status = :status', { status: 'error' })
      .getCount();

    // Total tokens used today
    const todayTokens = await this.usageRepo
      .createQueryBuilder('log')
      .select('COALESCE(SUM(log.tokens_used), 0)', 'total')
      .where('log.created_at >= :today', { today })
      .getRawOne();

    return {
      users: { total: totalUsers, premium: premiumUsers },
      today: {
        apiCalls: todayLogs,
        successful: todaySuccessful,
        errors: todayErrors,
        tokensUsed: parseInt(todayTokens?.total || '0'),
      },
      totalEmbeddings,
      estimatedCost: this.estimateCost(parseInt(todayTokens?.total || '0')),
    };
  }

  async getUsage(days: number = 7) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    // Daily breakdown
    const daily = await this.usageRepo
      .createQueryBuilder('log')
      .select("TO_CHAR(log.created_at, 'YYYY-MM-DD')", 'date')
      .addSelect('log.endpoint', 'endpoint')
      .addSelect('COUNT(*)', 'count')
      .addSelect('COALESCE(SUM(log.tokens_used), 0)', 'tokens')
      .addSelect('COALESCE(AVG(log.latency_ms), 0)', 'avgLatency')
      .where('log.created_at >= :since', { since })
      .groupBy("TO_CHAR(log.created_at, 'YYYY-MM-DD')")
      .addGroupBy('log.endpoint')
      .orderBy("TO_CHAR(log.created_at, 'YYYY-MM-DD')", 'DESC')
      .getRawMany();

    // Per-endpoint totals
    const byEndpoint = await this.usageRepo
      .createQueryBuilder('log')
      .select('log.endpoint', 'endpoint')
      .addSelect('COUNT(*)', 'count')
      .addSelect('COALESCE(SUM(log.tokens_used), 0)', 'tokens')
      .addSelect('COALESCE(AVG(log.latency_ms), 0)', 'avgLatency')
      .addSelect('log.model', 'model')
      .where('log.created_at >= :since', { since })
      .groupBy('log.endpoint')
      .addGroupBy('log.model')
      .orderBy('count', 'DESC')
      .getRawMany();

    // Total tokens and cost
    const totalTokens = byEndpoint.reduce((sum, e) => sum + parseInt(e.tokens || '0'), 0);

    return {
      period: { days, since: since.toISOString() },
      daily,
      byEndpoint,
      totalTokens,
      estimatedCost: this.estimateCost(totalTokens),
    };
  }

  async getUsers() {
    const users = await this.userRepo.find({
      order: { createdAt: 'DESC' },
    });

    // Get usage count per user for last 7 days
    const since = new Date();
    since.setDate(since.getDate() - 7);

    const userUsage = await this.usageRepo
      .createQueryBuilder('log')
      .select('log.user_id', 'userId')
      .addSelect('COUNT(*)', 'callCount')
      .addSelect('MAX(log.created_at)', 'lastActive')
      .where('log.created_at >= :since', { since })
      .groupBy('log.user_id')
      .getRawMany();

    const usageMap = new Map(userUsage.map((u) => [u.userId, u]));

    return users.map((user) => {
      const usage = usageMap.get(user.firebaseUid);
      return {
        uid: user.firebaseUid,
        email: user.email,
        isPremium: user.isPremium,
        createdAt: user.createdAt,
        weeklyApiCalls: parseInt(usage?.callCount || '0'),
        lastActive: usage?.lastActive || user.updatedAt,
      };
    });
  }

  async getRateLimits() {
    const users = await this.userRepo.find();
    const today = new Date().toISOString().split('T')[0];
    const limits: any[] = [];

    for (const user of users) {
      const endpoints = ['ai', 'image', 'embed', 'search'];
      const userLimits: Record<string, number> = {};

      for (const ep of endpoints) {
        const key = `ratelimit:${user.firebaseUid}:${ep}:${today}`;
        const val = await this.redis.get(key);
        userLimits[ep] = parseInt(val || '0');
      }

      const totalUsage = Object.values(userLimits).reduce((a, b) => a + b, 0);
      if (totalUsage > 0) {
        limits.push({
          uid: user.firebaseUid.substring(0, 8) + '...',
          email: user.email,
          isPremium: user.isPremium,
          usage: userLimits,
        });
      }
    }

    return limits;
  }

  async togglePremium(uid: string): Promise<boolean> {
    const user = await this.userRepo.findOne({ where: { firebaseUid: uid } });
    if (!user) return false;
    user.isPremium = !user.isPremium;
    await this.userRepo.save(user);
    return user.isPremium;
  }

  private estimateCost(tokens: number): { usd: number; breakdown: string } {
    // Approximate pricing (per 1M tokens)
    // gpt-4o-mini input: $0.15, output: $0.60 → avg ~$0.30
    // gpt-4o input: $2.50, output: $10.00 → avg ~$5.00
    // text-embedding-3-small: $0.02
    // Rough estimate: assume 70% embedding, 25% gpt-4o-mini, 5% gpt-4o
    const embeddingCost = tokens * 0.7 * 0.02 / 1_000_000;
    const miniCost = tokens * 0.25 * 0.30 / 1_000_000;
    const visionCost = tokens * 0.05 * 5.00 / 1_000_000;
    const total = embeddingCost + miniCost + visionCost;

    return {
      usd: Math.round(total * 10000) / 10000,
      breakdown: `embed: $${embeddingCost.toFixed(4)}, mini: $${miniCost.toFixed(4)}, vision: $${visionCost.toFixed(4)}`,
    };
  }
}
