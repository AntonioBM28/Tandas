import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RegistroDto } from './dto/registro.dto';
import * as bcrypt from 'bcrypt';
import { Usuario } from '@prisma/client';

export interface PublicUser {
  id: string;
  email: string;
  nombre: string;
  telefono: string | null;
  fotoPerfil: string | null;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  usuario: PublicUser;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  private getPublicUser(usuario: Usuario): PublicUser {
    return {
      id: usuario.id,
      email: usuario.email,
      nombre: usuario.nombre,
      telefono: usuario.telefono,
      fotoPerfil: usuario.fotoPerfil,
    };
  }

  async registro(dto: RegistroDto): Promise<AuthResponse> {
    const existing = await this.prisma.usuario.findUnique({
      where: { email: dto.email },
    });

    if (existing) {
      throw new ConflictException('El email ya está registrado');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const usuario = await this.prisma.usuario.create({
      data: {
        email: dto.email,
        passwordHash,
        nombre: dto.nombre,
        telefono: dto.telefono,
      },
    });

    return this.generateAuthResponse(usuario);
  }

  async validateUser(email: string, pass: string): Promise<Usuario> {
    const usuario = await this.prisma.usuario.findUnique({ where: { email } });
    if (!usuario) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const isMatch = await bcrypt.compare(pass, usuario.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    return usuario;
  }

  async login(usuario: Usuario): Promise<AuthResponse> {
    return this.generateAuthResponse(usuario);
  }

  async refreshTokens(rawRefreshToken: string): Promise<AuthResponse> {
    try {
      // 1. Verify the JWT signature
      const refreshSecret = this.configService.getOrThrow<string>('JWT_REFRESH_SECRET');
      const payload = this.jwtService.verify(rawRefreshToken, { secret: refreshSecret });
      const usuarioId = payload.sub;

      // 2. Fetch active tokens for user
      const storedTokens = await this.prisma.tokenRefresco.findMany({
        where: { usuarioId, revocado: false },
      });

      let validTokenId: string | null = null;

      // 3. Compare hash
      for (const stored of storedTokens) {
        const matches = await bcrypt.compare(rawRefreshToken, stored.tokenHash);
        if (matches && new Date() < stored.expiraEn) {
          validTokenId = stored.id;
          break;
        }
      }

      if (!validTokenId) {
        throw new UnauthorizedException('Refresh token inválido, revocado o expirado');
      }

      // 4. Revoke used token (rotation)
      await this.prisma.tokenRefresco.update({
        where: { id: validTokenId },
        data: { revocado: true },
      });

      const usuario = await this.prisma.usuario.findUnique({
        where: { id: usuarioId },
      });

      if (!usuario) {
        throw new UnauthorizedException('Usuario no encontrado');
      }

      return this.generateAuthResponse(usuario);
    } catch (e) {
      throw new UnauthorizedException('Refresh token inválido o expirado');
    }
  }

  async logout(rawRefreshToken: string): Promise<void> {
    try {
      // Decode the token (no need to throw if it's expired, we just want to revoke it if valid format)
      const payload = this.jwtService.decode(rawRefreshToken) as any;
      if (!payload || !payload.sub) return;

      const usuarioId = payload.sub;

      const storedTokens = await this.prisma.tokenRefresco.findMany({
        where: { usuarioId, revocado: false },
      });

      for (const stored of storedTokens) {
        const matches = await bcrypt.compare(rawRefreshToken, stored.tokenHash);
        if (matches) {
          await this.prisma.tokenRefresco.update({
            where: { id: stored.id },
            data: { revocado: true },
          });
          break;
        }
      }
    } catch (e) {
      // Ignore token decode errors on logout
    }
  }

  private async generateAuthResponse(usuario: Usuario): Promise<AuthResponse> {
    const payload = { sub: usuario.id, email: usuario.email };

    // Access token (short lived)
    const accessToken = this.jwtService.sign(payload);

    // Refresh token (long lived)
    const refreshSecret = this.configService.getOrThrow<string>('JWT_REFRESH_SECRET');
    const refreshTokenPlain = this.jwtService.sign(payload, {
      secret: refreshSecret,
      expiresIn: '7d',
    });

    const tokenHash = await bcrypt.hash(refreshTokenPlain, 10);

    const expiraEn = new Date();
    expiraEn.setDate(expiraEn.getDate() + 7);

    await this.prisma.tokenRefresco.create({
      data: {
        tokenHash,
        usuarioId: usuario.id,
        expiraEn,
      },
    });

    return {
      accessToken,
      refreshToken: refreshTokenPlain,
      usuario: this.getPublicUser(usuario),
    };
  }
}
