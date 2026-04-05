import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('memory_embeddings')
export class MemoryEmbedding {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'memory_id' })
  memoryId: string;

  // pgvector stored as float array, cast to vector in raw queries
  @Column('float4', { array: true })
  embedding: number[];

  @Column({ name: 'text_hash', nullable: true })
  textHash: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
