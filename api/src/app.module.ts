import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { AiModule } from './ai/ai.module';
import { EmbeddingModule } from './embedding/embedding.module';
import { SearchModule } from './search/search.module';
import { RateLimitModule } from './rate-limit/rate-limit.module';
import { HealthModule } from './health/health.module';
import { AdminModule } from './admin/admin.module';
import { MemoryEmbedding } from './search/entities/memory-embedding.entity';
import { UserProfile } from './auth/entities/user-profile.entity';
import { ApiUsageLog } from './common/entities/api-usage-log.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get('DB_HOST', '192.168.50.201'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get('DB_USERNAME', 'app_user'),
        password: config.get('DB_PASSWORD'),
        database: config.get('DB_DATABASE', 'dailymemory'),
        entities: [MemoryEmbedding, UserProfile, ApiUsageLog],
        synchronize: false,
      }),
    }),
    AuthModule,
    AiModule,
    EmbeddingModule,
    SearchModule,
    RateLimitModule,
    HealthModule,
    AdminModule,
  ],
})
export class AppModule {}
