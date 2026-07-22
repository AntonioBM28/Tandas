import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-local';
import { AuthService } from '../auth.service';
import { Usuario } from '@prisma/client';

@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private readonly authService: AuthService) {
    super({ usernameField: 'email' });
  }

  async validate(email: string, password: string): Promise<Omit<Usuario, 'passwordHash'>> {
    const usuario = await this.authService.validateUser(email, password);
    if (!usuario) {
      throw new UnauthorizedException('Credenciales inválidas');
    }
    return usuario;
  }
}
