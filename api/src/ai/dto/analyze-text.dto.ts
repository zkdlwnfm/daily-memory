import { IsString, IsNotEmpty, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AnalyzeTextDto {
  @ApiProperty({ description: 'Text content to analyze' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(10000)
  text: string;
}

export class AnalyzeImageDto {
  @ApiProperty({ description: 'Base64 encoded JPEG image' })
  @IsString()
  @IsNotEmpty()
  imageBase64: string;
}

export class PersonExtracted {
  name: string;
  relationship: string;
}

export class TaskExtractedDto {
  title: string;
  description?: string;
  dueDate?: string;
  urgency: number;
  importance: number;
  relatedPerson?: string;
}

export class AnalysisResultDto {
  persons: PersonExtracted[];
  location?: string;
  date?: string;
  amount?: number;
  tags: string[];
  category: string;
  mood: string;
  moodScore: number;
  summary: string;
  tasks?: TaskExtractedDto[];
}

export class ImageAnalysisResultDto {
  objects: string[];
  scene: string;
  text?: string;
  faces: number;
  description: string;
  suggestedTags: string[];
}
