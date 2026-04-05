import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { ApiUsageLog } from '../common/entities/api-usage-log.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ApiUsageLog])],
  controllers: [AiController],
  providers: [AiService],
  exports: [AiService],
})
export class AiModule {}
