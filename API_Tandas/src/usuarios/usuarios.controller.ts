import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  ParseUUIDPipe,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsuariosService } from './usuarios.service';
import { CreateUsuarioDto } from './dto/create-usuario.dto';
import { UpdateUsuarioDto } from './dto/update-usuario.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { multerProfileOptions } from './multer/multer-profile.config';
import { JwtPayload } from '../auth/strategies/jwt.strategy';

interface RequestWithUser extends Request {
  user: JwtPayload;
}

@Controller('usuarios')
export class UsuariosController {
  constructor(private readonly usuariosService: UsuariosService) {}

  /**
   * POST /usuarios/registro
   * Public endpoint to register a new user.
   */
  @Post('registro')
  async registro(@Body() createUsuarioDto: CreateUsuarioDto) {
    return this.usuariosService.create(createUsuarioDto);
  }

  /**
   * GET /usuarios/me
   * Returns the authenticated user's profile.
   */
  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getMe(@Request() req: RequestWithUser) {
    return this.usuariosService.findOne(req.user.sub);
  }

  /**
   * PATCH /usuarios/me
   * Updates the authenticated user's profile (nombre, telefono).
   */
  @UseGuards(JwtAuthGuard)
  @Patch('me')
  async updateMe(
    @Request() req: RequestWithUser,
    @Body() updateUsuarioDto: UpdateUsuarioDto,
  ) {
    return this.usuariosService.update(req.user.sub, updateUsuarioDto);
  }

  /**
   * PATCH /usuarios/me/foto
   * Uploads a profile photo. Accepts multipart/form-data with field "foto".
   * Stores file locally and saves relative path in DB.
   */
  @UseGuards(JwtAuthGuard)
  @Patch('me/foto')
  @UseInterceptors(FileInterceptor('foto', multerProfileOptions))
  async uploadFotoPerfil(
    @Request() req: RequestWithUser,
    @UploadedFile() file: Express.Multer.File | undefined,
  ) {
    if (!file) {
      throw new BadRequestException('No se proporcionó ninguna imagen');
    }
    // Store relative path (e.g. /uploads/perfiles/uuid.jpg)
    const relativePath = `/uploads/perfiles/${file.filename}`;
    return this.usuariosService.updateFotoPerfil(req.user.sub, relativePath);
  }

  /**
   * GET /usuarios/:id
   * Returns a user by ID (protected).
   */
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.usuariosService.findOne(id);
  }
}
