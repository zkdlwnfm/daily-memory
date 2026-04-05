import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import OpenAI from 'openai';
import * as crypto from 'crypto';
import { MemoryEmbedding } from '../search/entities/memory-embedding.entity';
import { ApiUsageLog } from '../common/entities/api-usage-log.entity';

@Injectable()
export class EmbeddingService {
  private openai: OpenAI;
  private readonly model = 'text-embedding-3-small';

  constructor(
    private configService: ConfigService,
    private dataSource: DataSource,
    @InjectRepository(MemoryEmbedding)
    private embeddingRepo: Repository<MemoryEmbedding>,
    @InjectRepository(ApiUsageLog)
    private usageLogRepo: Repository<ApiUsageLog>,
  ) {
    this.openai = new OpenAI({
      apiKey: this.configService.get('OPENAI_API_KEY'),
    });
  }

  async generateEmbedding(text: string, userId: string): Promise<number[]> {
    const start = Date.now();

    try {
      const response = await this.openai.embeddings.create({
        model: this.model,
        input: text,
      });

      const embedding = response.data[0].embedding;
      await this.logUsage(userId, 'embeddings', response.usage?.total_tokens, this.model, Date.now() - start, 'success');
      return embedding;
    } catch (error) {
      await this.logUsage(userId, 'embeddings', undefined,this.model, Date.now() - start, 'error');
      throw error;
    }
  }

  async generateBatchEmbeddings(texts: string[], userId: string): Promise<number[][]> {
    const start = Date.now();

    try {
      const response = await this.openai.embeddings.create({
        model: this.model,
        input: texts,
      });

      const embeddings = response.data.map((d) => d.embedding);
      await this.logUsage(userId, 'embeddings/batch', response.usage?.total_tokens, this.model, Date.now() - start, 'success');
      return embeddings;
    } catch (error) {
      await this.logUsage(userId, 'embeddings/batch', undefined,this.model, Date.now() - start, 'error');
      throw error;
    }
  }

  async storeEmbedding(userId: string, memoryId: string, text: string): Promise<{ memoryId: string; dimensions: number; stored: boolean }> {
    const textHash = crypto.createHash('sha256').update(text).digest('hex');

    // Check if embedding already exists with same text
    const existing = await this.embeddingRepo.findOne({
      where: { userId, memoryId },
    });

    if (existing && existing.textHash === textHash) {
      return { memoryId, dimensions: 1536, stored: true };
    }

    const embedding = await this.generateEmbedding(text, userId);

    // Use raw query for pgvector insert
    await this.dataSource.query(
      `INSERT INTO memory_embeddings (user_id, memory_id, embedding, text_hash)
       VALUES ($1, $2, $3::vector, $4)
       ON CONFLICT (user_id, memory_id)
       DO UPDATE SET embedding = EXCLUDED.embedding, text_hash = EXCLUDED.text_hash, updated_at = NOW()`,
      [userId, memoryId, `[${embedding.join(',')}]`, textHash],
    );

    return { memoryId, dimensions: embedding.length, stored: true };
  }

  async deleteEmbedding(userId: string, memoryId: string): Promise<void> {
    await this.embeddingRepo.delete({ userId, memoryId });
  }

  private async logUsage(userId: string, endpoint: string, tokens: number | undefined, model: string, latencyMs: number, status: string) {
    const log = this.usageLogRepo.create({ userId, endpoint, tokensUsed: tokens, model, latencyMs, status });
    await this.usageLogRepo.save(log);
  }
}
