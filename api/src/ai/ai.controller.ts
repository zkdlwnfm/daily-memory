import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AiService } from './ai.service';
import { AnalyzeTextDto, AnalyzeImageDto } from './dto/analyze-text.dto';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { CurrentUser, AuthUser } from '../auth/decorators/current-user.decorator';

@ApiTags('AI')
@ApiBearerAuth()
@UseGuards(FirebaseAuthGuard)
@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('analyze')
  async analyzeText(@Body() dto: AnalyzeTextDto, @CurrentUser() user: AuthUser) {
    return this.aiService.analyzeText(dto.text, user.uid);
  }

  @Post('analyze-image')
  async analyzeImage(@Body() dto: AnalyzeImageDto, @CurrentUser() user: AuthUser) {
    return this.aiService.analyzeImage(dto.imageBase64, user.uid);
  }
}
