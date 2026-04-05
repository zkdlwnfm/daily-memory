import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { EmbeddingService } from '../embedding/embedding.service';
import { SearchResultDto } from './dto/semantic-search.dto';

@Injectable()
export class SearchService {
  constructor(
    private dataSource: DataSource,
    private embeddingService: EmbeddingService,
  ) {}

  async semanticSearch(
    userId: string,
    query: string,
    limit: number = 10,
    threshold: number = 0.3,
  ): Promise<SearchResultDto[]> {
    // Generate query embedding
    const queryEmbedding = await this.embeddingService.generateEmbedding(query, userId);
    const vectorStr = `[${queryEmbedding.join(',')}]`;

    // pgvector cosine similarity search
    const results = await this.dataSource.query(
      `SELECT memory_id AS "memoryId",
              1 - (embedding <=> $1::vector) AS similarity
       FROM memory_embeddings
       WHERE user_id = $2
         AND 1 - (embedding <=> $1::vector) >= $3
       ORDER BY embedding <=> $1::vector
       LIMIT $4`,
      [vectorStr, userId, threshold, limit],
    );

    return results.map((r: any) => ({
      memoryId: r.memoryId,
      similarity: parseFloat(r.similarity),
    }));
  }
}
