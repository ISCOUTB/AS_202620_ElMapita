import { Module } from '@nestjs/common';
import { ConfigModule } from '../../shared/config/config.module';
import { AuthController } from './interfaces/auth.controller';
import { SignInUseCase, SignUpUseCase, RefreshTokenUseCase, SignOutUseCase, GetCurrentUserUseCase, UpdateUserRoleUseCase } from './application/use-cases';
import { SupabaseAuthClientImpl } from './infrastructure/supabase/supabase-auth-client';

@Module({
  imports: [ConfigModule],
  controllers: [AuthController],
  providers: [
    SignInUseCase,
    SignUpUseCase,
    RefreshTokenUseCase,
    SignOutUseCase,
    GetCurrentUserUseCase,
    UpdateUserRoleUseCase,
    {
      provide: 'SupabaseAuthClient',
      useClass: SupabaseAuthClientImpl,
    },
  ],
  exports: [
    SignInUseCase,
    SignUpUseCase,
    RefreshTokenUseCase,
    SignOutUseCase,
    GetCurrentUserUseCase,
    UpdateUserRoleUseCase,
  ],
})
export class AuthModule {}