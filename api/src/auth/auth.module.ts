import { Module, Global, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import * as admin from 'firebase-admin';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { UserProfile } from './entities/user-profile.entity';
import * as fs from 'fs';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([UserProfile])],
  providers: [FirebaseAuthGuard],
  exports: [FirebaseAuthGuard, TypeOrmModule],
})
export class AuthModule implements OnModuleInit {
  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const serviceAccountPath = this.configService.get<string>(
      'FIREBASE_SERVICE_ACCOUNT_PATH',
      '/app/secrets/firebase-service-account.json',
    );

    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = JSON.parse(
        fs.readFileSync(serviceAccountPath, 'utf-8'),
      );
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else {
      // Fallback: initialize without credentials (for dev)
      console.warn('Firebase service account not found, auth will fail');
      admin.initializeApp();
    }
  }
}
