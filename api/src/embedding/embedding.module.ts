import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmbeddingController } from './embedding.controller';
import { EmbeddingService } from './embedding.service';
import { MemoryEmbedding } from '../search/entities/memory-embedding.entity';
import { ApiUsageLog } from '../common/entities/api-usage-log.entity';

@Module({
  imports: [TypeOrmModule.forFeature([MemoryEmbedding, ApiUsageLog])],
  controllers: [EmbeddingController],
  providers: [EmbeddingService],
  exports: [EmbeddingService],
})
export class EmbeddingModule {}
