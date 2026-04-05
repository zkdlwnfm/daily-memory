import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('api_usage_logs')
export class ApiUsageLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column()
  endpoint: string;

  @Column({ name: 'tokens_used', nullable: true })
  tokensUsed?: number;

  @Column({ nullable: true })
  model: string;

  @Column({ name: 'latency_ms', nullable: true })
  latencyMs: number;

  @Column({ nullable: true })
  status: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
