import { Controller, Post, Body, Get, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { SignInUseCase, SignUpUseCase, RefreshTokenUseCase, SignOutUseCase, GetCurrentUserUseCase, UpdateUserRoleUseCase } from '../application/use-cases';
import type { SignInInput, SignUpInput, RefreshTokenInput, UpdateUserRoleInput } from '../domain';

@ApiTags('Autenticación')
@Controller('api/v1/auth')
export class AuthController {
  constructor(
    private readonly signInUseCase: SignInUseCase,
    private readonly signUpUseCase: SignUpUseCase,
    private readonly refreshTokenUseCase: RefreshTokenUseCase,
    private readonly signOutUseCase: SignOutUseCase,
    private readonly getCurrentUserUseCase: GetCurrentUserUseCase,
    private readonly updateUserRoleUseCase: UpdateUserRoleUseCase,
  ) {}

  @Post('signin')
  @ApiOperation({ summary: 'Iniciar sesión con email y contraseña' })
  @ApiResponse({ status: 200, description: 'Usuario autenticado con tokens' })
  @ApiResponse({ status: 401, description: 'Credenciales inválidas' })
  async signIn(@Body() input: SignInInput) {
    return this.signInUseCase.execute(input);
  }

  @Post('signup')
  @ApiOperation({ summary: 'Registrar nuevo usuario' })
  @ApiResponse({ status: 201, description: 'Usuario registrado con tokens' })
  @ApiResponse({ status: 400, description: 'Datos inválidos o email ya existe' })
  async signUp(@Body() input: SignUpInput) {
    return this.signUpUseCase.execute(input);
  }

  @Post('refresh')
  @ApiOperation({ summary: 'Refrescar access token' })
  @ApiResponse({ status: 200, description: 'Nuevos tokens' })
  @ApiResponse({ status: 401, description: 'Refresh token inválido o expirado' })
  async refresh(@Body() input: RefreshTokenInput) {
    return this.refreshTokenUseCase.execute(input);
  }

  @Post('signout')
  @ApiOperation({ summary: 'Cerrar sesión' })
  @ApiResponse({ status: 200, description: 'Sesión cerrada' })
  async signOut() {
    return this.signOutUseCase.execute();
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Obtener usuario actual' })
  @ApiResponse({ status: 200, description: 'Datos del usuario autenticado' })
  @ApiResponse({ status: 401, description: 'Token inválido o expirado' })
  async getCurrentUser(@Request() req: any) {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new Error('Missing or invalid authorization header');
    }
    const accessToken = authHeader.substring(7);
    return this.getCurrentUserUseCase.execute({ accessToken });
  }

  @Post('users/:userId/role')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Actualizar rol de usuario (solo admin)' })
  @ApiResponse({ status: 200, description: 'Rol actualizado' })
  @ApiResponse({ status: 403, description: 'No autorizado' })
  async updateUserRole(@Body() input: UpdateUserRoleInput) {
    return this.updateUserRoleUseCase.execute(input);
  }
}