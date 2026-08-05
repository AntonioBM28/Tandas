import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthService, AuthResponse } from './auth.service';
import { LocalAuthGuard } from './guards/local-auth.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RegistroDto } from './dto/registro.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ConfirmarCodigoDispositivoDto } from './dto/codigo-dispositivo.dto';
import { UsuarioActual } from './decorators/usuario-actual.decorator';
import { Usuario } from '@prisma/client';
import { JwtPayload } from './strategies/jwt.strategy';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('registro')
  async registro(@Body() dto: RegistroDto): Promise<AuthResponse> {
    return this.authService.registro(dto);
  }

  @UseGuards(LocalAuthGuard)
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(
    @UsuarioActual() usuario: Usuario,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    @Body() _loginDto: LoginDto,
  ): Promise<AuthResponse> {
    return this.authService.login(usuario);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshTokenDto): Promise<AuthResponse> {
    return this.authService.refreshTokens(dto.refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  async logout(
    @Body() dto: RefreshTokenDto,
  ): Promise<{ message: string }> {
    await this.authService.logout(dto.refreshToken);
    return { message: 'Sesión cerrada correctamente' };
  }

  // Vinculación de dispositivos sin teclado cómodo (el reloj) vía código.

  @Post('dispositivo/generar-codigo')
  @HttpCode(HttpStatus.OK)
  async generarCodigoDispositivo() {
    return this.authService.generarCodigoDispositivo();
  }

  @UseGuards(JwtAuthGuard)
  @Post('dispositivo/confirmar')
  @HttpCode(HttpStatus.OK)
  async confirmarCodigoDispositivo(
    @Body() dto: ConfirmarCodigoDispositivoDto,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.authService.confirmarCodigoDispositivo(dto.codigo, usuario.sub);
  }

  @Get('dispositivo/estado/:codigo')
  async consultarCodigoDispositivo(@Param('codigo') codigo: string) {
    return this.authService.consultarCodigoDispositivo(codigo);
  }
}
