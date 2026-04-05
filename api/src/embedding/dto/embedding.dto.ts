import { IsString, IsNotEmpty, IsArray, MaxLength, ArrayMaxSize } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class GenerateEmbeddingDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(10000)
  text: string;
}

export class StoreEmbeddingDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  memoryId: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(10000)
  text: string;
}

export class BatchEmbeddingDto {
  @ApiProperty()
  @IsArray()
  @ArrayMaxSize(20)
  texts: string[];
}
