import { Controller, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { EmbeddingService } from './embedding.service';
import { GenerateEmbeddingDto, StoreEmbeddingDto, BatchEmbeddingDto } from './dto/embedding.dto';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { CurrentUser, AuthUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Embeddings')
@ApiBearerAuth()
@UseGuards(FirebaseAuthGuard)
@Controller('embeddings')
export class EmbeddingController {
  constructor(private readonly embeddingService: EmbeddingService) {}

  @Post()
  async generate(@Body() dto: GenerateEmbeddingDto, @CurrentUser() user: AuthUser) {
    const embedding = await this.embeddingService.generateEmbedding(dto.text, user.uid);
    return { embedding, dimensions: embedding.length };
  }

  @Post('batch')
  async batch(@Body() dto: BatchEmbeddingDto, @CurrentUser() user: AuthUser) {
    const embeddings = await this.embeddingService.generateBatchEmbeddings(dto.texts, user.uid);
    return { embeddings, count: embeddings.length };
  }

  @Post('store')
  async store(@Body() dto: StoreEmbeddingDto, @CurrentUser() user: AuthUser) {
    return this.embeddingService.storeEmbedding(user.uid, dto.memoryId, dto.text);
  }

  @Delete(':memoryId')
  async delete(@Param('memoryId') memoryId: string, @CurrentUser() user: AuthUser) {
    await this.embeddingService.deleteEmbedding(user.uid, memoryId);
    return { deleted: true };
  }
}
