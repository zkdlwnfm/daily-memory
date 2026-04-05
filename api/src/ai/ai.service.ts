import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import OpenAI from 'openai';
import { AnalysisResultDto, ImageAnalysisResultDto } from './dto/analyze-text.dto';
import { ApiUsageLog } from '../common/entities/api-usage-log.entity';

@Injectable()
export class AiService {
  private openai: OpenAI;

  constructor(
    private configService: ConfigService,
    @InjectRepository(ApiUsageLog)
    private usageLogRepo: Repository<ApiUsageLog>,
  ) {
    this.openai = new OpenAI({
      apiKey: this.configService.get('OPENAI_API_KEY'),
    });
  }

  async analyzeText(text: string, userId: string): Promise<AnalysisResultDto> {
    const start = Date.now();
    const prompt = `Analyze the following personal memory/diary entry and extract structured information.
Return a JSON object with these fields:
- persons: array of objects with "name" and "relationship" (one of "FAMILY", "FRIEND", "COLLEAGUE", "BUSINESS", "ACQUAINTANCE", "OTHER"). Infer relationship from context clues (e.g. "my son" = FAMILY, "my colleague" = COLLEAGUE, "met someone" = ACQUAINTANCE). Default to "OTHER" if unclear.
- location: location mentioned (or null)
- date: any specific date/time mentioned (or null)
- amount: any monetary amount mentioned (or null)
- tags: array of relevant tags/keywords
- category: one of "EVENT", "PROMISE", "MEETING", "FINANCIAL", "GENERAL"
- summary: one-line summary

Text: "${text}"

Respond ONLY with valid JSON, no markdown.`;

    try {
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.3,
        max_tokens: 500,
      });

      const content = response.choices[0]?.message?.content || '{}';
      const result = JSON.parse(content) as AnalysisResultDto;

      await this.logUsage(userId, 'ai/analyze', response.usage?.total_tokens, 'gpt-4o-mini', Date.now() - start, 'success');

      return result;
    } catch (error) {
      await this.logUsage(userId, 'ai/analyze', undefined,'gpt-4o-mini', Date.now() - start, 'error');
      throw error;
    }
  }

  async analyzeImage(imageBase64: string, userId: string): Promise<ImageAnalysisResultDto> {
    const start = Date.now();
    const prompt = `Analyze this image and extract:
- objects: array of objects/items visible
- scene: overall scene description
- text: any text visible (OCR), or null
- faces: number of faces detected
- description: detailed description of the image
- suggestedTags: array of tags for categorization

Respond ONLY with valid JSON, no markdown.`;

    try {
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: prompt },
              { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${imageBase64}`, detail: 'low' } },
            ],
          },
        ],
        temperature: 0.3,
        max_tokens: 500,
      });

      const content = response.choices[0]?.message?.content || '{}';
      const result = JSON.parse(content) as ImageAnalysisResultDto;

      await this.logUsage(userId, 'ai/analyze-image', response.usage?.total_tokens, 'gpt-4o', Date.now() - start, 'success');

      return result;
    } catch (error) {
      await this.logUsage(userId, 'ai/analyze-image', undefined,'gpt-4o', Date.now() - start, 'error');
      throw error;
    }
  }

  private async logUsage(userId: string, endpoint: string, tokens: number | undefined, model: string, latencyMs: number, status: string) {
    const log = this.usageLogRepo.create({ userId, endpoint, tokensUsed: tokens, model, latencyMs, status });
    await this.usageLogRepo.save(log);
  }
}
