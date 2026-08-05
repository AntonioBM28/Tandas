import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RegistroDto } from './dto/registro.dto';
import * as bcrypt from 'bcrypt';
import { Usuario, EstadoCodigoDispositivo, Prisma } from '@prisma/client';

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

  /**
   * Un dispositivo sin teclado cómodo (el reloj) pide un código de 6
   * dígitos, vigente unos minutos, para que el usuario lo confirme desde
   * un dispositivo donde ya tiene sesión (el celular).
   */
  async generarCodigoDispositivo(): Promise<{ codigo: string; expiraEn: Date }> {
    const expiraEn = new Date();
    expiraEn.setMinutes(expiraEn.getMinutes() + 10);

    for (let intento = 0; intento < 5; intento++) {
      const codigo = Math.floor(100000 + Math.random() * 900000).toString();
      try {
        const creado = await this.prisma.codigoDispositivo.create({
          data: { codigo, expiraEn },
        });
        return { codigo: creado.codigo, expiraEn: creado.expiraEn };
      } catch (error) {
        if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
          continue; // código ya en uso, intenta con otro
        }
        throw error;
      }
    }
    throw new BadRequestException('No se pudo generar un código, intenta de nuevo');
  }

  /**
   * El usuario, ya logueado en el celular, confirma que el código que ve
   * en el reloj le pertenece.
   */
  async confirmarCodigoDispositivo(codigo: string, usuarioId: string): Promise<{ message: string }> {
    const registro = await this.prisma.codigoDispositivo.findUnique({ where: { codigo } });

    if (!registro || registro.estado !== EstadoCodigoDispositivo.PENDIENTE) {
      throw new NotFoundException('Código inválido o ya utilizado');
    }
    if (registro.expiraEn < new Date()) {
      throw new BadRequestException('El código expiró, genera uno nuevo desde el reloj');
    }

    await this.prisma.codigoDispositivo.update({
      where: { id: registro.id },
      data: { estado: EstadoCodigoDispositivo.CONFIRMADO, usuarioId },
    });

    return { message: 'Dispositivo vinculado correctamente' };
  }

  /**
   * El reloj pregunta periódicamente si ya lo confirmaron. Una vez
   * confirmado, se le entregan tokens de sesión reales (iguales a los de
   * un login normal) y el código se borra para que no se pueda reusar.
   */
  async consultarCodigoDispositivo(
    codigo: string,
  ): Promise<{ estado: 'PENDIENTE' } | ({ estado: 'CONFIRMADO' } & AuthResponse)> {
    const registro = await this.prisma.codigoDispositivo.findUnique({
      where: { codigo },
      include: { usuario: true },
    });

    if (!registro) {
      throw new NotFoundException('Código inválido o expirado');
    }
    if (registro.expiraEn < new Date()) {
      await this.prisma.codigoDispositivo.delete({ where: { id: registro.id } }).catch(() => undefined);
      throw new NotFoundException('El código expiró, genera uno nuevo desde el reloj');
    }
    if (registro.estado === EstadoCodigoDispositivo.PENDIENTE || !registro.usuario) {
      return { estado: 'PENDIENTE' };
    }

    const authResponse = await this.generateAuthResponse(registro.usuario);
    // Un solo uso: ya se entregaron los tokens, el código deja de servir.
    await this.prisma.codigoDispositivo.delete({ where: { id: registro.id } });

    return { estado: 'CONFIRMADO', ...authResponse };
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
