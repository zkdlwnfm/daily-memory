import { IsString, IsNotEmpty, IsArray, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ChatMessageDto {
  @ApiProperty()
  @IsString()
  role: 'user' | 'assistant';

  @ApiProperty()
  @IsString()
  content: string;
}

export class ChatDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  message: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  history?: ChatMessageDto[];
}
