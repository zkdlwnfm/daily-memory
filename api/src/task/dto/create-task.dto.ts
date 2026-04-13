import { IsString, IsNotEmpty, IsOptional, IsEnum, IsBoolean, IsNumber, IsDateString, MaxLength } from 'class-validator';

export class CreateTaskDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsNotEmpty()
  memoryId: string;

  @IsString()
  @IsOptional()
  personId?: string;

  @IsDateString()
  @IsOptional()
  dueDate?: string;

  @IsString()
  @IsOptional()
  quadrant?: string;

  @IsBoolean()
  @IsOptional()
  isAiSuggested?: boolean;

  @IsNumber()
  @IsOptional()
  aiConfidence?: number;
}

export class UpdateTaskDto {
  @IsString()
  @IsOptional()
  @MaxLength(500)
  title?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  personId?: string;

  @IsDateString()
  @IsOptional()
  dueDate?: string;

  @IsString()
  @IsOptional()
  quadrant?: string;

  @IsString()
  @IsOptional()
  status?: string;
}

export class TaskQueryDto {
  @IsString()
  @IsOptional()
  status?: string;

  @IsString()
  @IsOptional()
  quadrant?: string;

  @IsString()
  @IsOptional()
  personId?: string;

  @IsDateString()
  @IsOptional()
  from?: string;

  @IsDateString()
  @IsOptional()
  to?: string;
}
