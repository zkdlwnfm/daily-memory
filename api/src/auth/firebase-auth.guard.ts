import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as admin from 'firebase-admin';
import { UserProfile } from './entities/user-profile.entity';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(
    @InjectRepository(UserProfile)
    private userProfileRepo: Repository<UserProfile>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid authorization header');
    }

    const token = authHeader.replace('Bearer ', '');

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      request.user = {
        uid: decoded.uid,
        email: decoded.email,
      };

      // Ensure user profile exists
      await this.ensureUserProfile(decoded.uid, decoded.email);

      return true;
    } catch (error) {
      throw new UnauthorizedException('Invalid or expired Firebase token');
    }
  }

  private async ensureUserProfile(uid: string, email?: string) {
    let profile = await this.userProfileRepo.findOne({
      where: { firebaseUid: uid },
    });

    if (!profile) {
      profile = this.userProfileRepo.create({
        firebaseUid: uid,
        email: email,
        isPremium: false,
      });
      await this.userProfileRepo.save(profile);
    }
  }
}
