import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('tasks')
export class TaskEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'memory_id', nullable: true })
  memoryId: string;

  @Column({ name: 'person_id', nullable: true })
  personId: string;

  @Column({ length: 500 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ name: 'due_date', type: 'timestamptz', nullable: true })
  dueDate: Date;

  @Column({ length: 4 })
  quadrant: string;

  @Column({ length: 20, default: 'open' })
  status: string;

  @Column({ name: 'is_ai_suggested', default: true })
  isAiSuggested: boolean;

  @Column({ name: 'ai_confidence', type: 'float', nullable: true })
  aiConfidence: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
