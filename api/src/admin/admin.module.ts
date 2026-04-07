import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { UserProfile } from '../auth/entities/user-profile.entity';
import { ApiUsageLog } from '../common/entities/api-usage-log.entity';
import { MemoryEmbedding } from '../search/entities/memory-embedding.entity';

@Module({
  imports: [TypeOrmModule.forFeature([UserProfile, ApiUsageLog, MemoryEmbedding])],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
