import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('user_profiles')
export class UserProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'firebase_uid', unique: true })
  firebaseUid: string;

  @Column({ nullable: true })
  email?: string;

  @Column({ name: 'is_premium', default: false })
  isPremium: boolean;

  @Column({ name: 'daily_ai_count', default: 0 })
  dailyAiCount: number;

  @Column({ name: 'daily_embed_count', default: 0 })
  dailyEmbedCount: number;

  @Column({ name: 'daily_image_count', default: 0 })
  dailyImageCount: number;

  @Column({ name: 'daily_search_count', default: 0 })
  dailySearchCount: number;

  @Column({ name: 'count_reset_at', type: 'timestamptz', default: () => 'NOW()' })
  countResetAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
