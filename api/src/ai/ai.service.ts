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
    const today = new Date().toISOString().split('T')[0];
    const prompt = `Analyze the following personal memory/diary entry and extract structured information.
Return a JSON object with these fields:
- persons: array of objects with "name" and "relationship" (one of "FAMILY", "FRIEND", "COLLEAGUE", "BUSINESS", "ACQUAINTANCE", "OTHER"). Infer relationship from context clues (e.g. "my son" = FAMILY, "my colleague" = COLLEAGUE, "met someone" = ACQUAINTANCE). Default to "OTHER" if unclear.
- location: location mentioned (or null)
- date: any specific date/time mentioned (or null)
- amount: any monetary amount mentioned (or null)
- tags: array of relevant tags/keywords
- category: one of "EVENT", "PROMISE", "MEETING", "FINANCIAL", "GENERAL"
- mood: one of "happy", "sad", "excited", "anxious", "grateful", "angry", "calm", "nostalgic", "neutral". Infer from tone and content.
- moodScore: integer 1-10 (1=very negative, 5=neutral, 10=very positive)
- summary: one-line summary
- tasks: array of actionable tasks/promises found in the text. Each task object has:
  - title: short actionable description
  - description: longer context (or null)
  - dueDate: ISO date string if a deadline is mentioned, convert relative dates using today=${today} (e.g. "next Wednesday", "by Friday") to absolute dates. null if no date.
  - urgency: integer 1-5 (5=most urgent)
  - importance: integer 1-5 (5=most important)
  - relatedPerson: name of the person this task relates to (or null)
  If no actionable tasks or promises are found, return an empty array.

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

  async chat(message: string, history: Array<{ role: string; content: string }>, userId: string): Promise<{ reply: string }> {
    const start = Date.now();

    // Find relevant memories via pgvector
    let contextMemories = '';
    try {
      const embeddingResponse = await this.openai.embeddings.create({
        model: 'text-embedding-3-small',
        input: message,
      });
      const queryEmbedding = embeddingResponse.data[0].embedding;
      const vectorStr = `[${queryEmbedding.join(',')}]`;

      const results = await this.usageLogRepo.manager.query(
        `SELECT memory_id, 1 - (embedding <=> $1::vector) AS similarity
         FROM memory_embeddings
         WHERE user_id = $2 AND 1 - (embedding <=> $1::vector) >= 0.3
         ORDER BY embedding <=> $1::vector LIMIT 5`,
        [vectorStr, userId],
      );

      if (results.length > 0) {
        // Fetch memory contents from Firestore would be ideal,
        // but we'll use the memory IDs as context hints
        contextMemories = `\n\nRelevant memory IDs found: ${results.map((r: any) => `${r.memory_id} (${(r.similarity * 100).toFixed(0)}% match)`).join(', ')}`;
      }
    } catch {
      // pgvector search failed, proceed without context
    }

    const systemPrompt = `You are a personal memory assistant. The user has been recording their daily memories, and you help them recall and reflect on their experiences.
Be warm, conversational, and helpful. If you find relevant memories, reference them naturally.
Keep responses concise (under 150 words) unless the user asks for details.${contextMemories}`;

    const messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = [
      { role: 'system', content: systemPrompt },
      ...history.slice(-10).map((h) => ({
        role: h.role as 'user' | 'assistant',
        content: h.content,
      })),
      { role: 'user', content: message },
    ];

    try {
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages,
        temperature: 0.7,
        max_tokens: 300,
      });

      const reply = response.choices[0]?.message?.content || "I couldn't process that. Try again?";
      await this.logUsage(userId, 'ai/chat', response.usage?.total_tokens, 'gpt-4o-mini', Date.now() - start, 'success');

      return { reply };
    } catch (error) {
      await this.logUsage(userId, 'ai/chat', undefined, 'gpt-4o-mini', Date.now() - start, 'error');
      throw error;
    }
  }

  private async logUsage(userId: string, endpoint: string, tokens: number | undefined, model: string, latencyMs: number, status: string) {
    const log = this.usageLogRepo.create({ userId, endpoint, tokensUsed: tokens, model, latencyMs, status });
    await this.usageLogRepo.save(log);
  }
}
