import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUsuarioDto } from './dto/create-usuario.dto';
import { UpdateUsuarioDto } from './dto/update-usuario.dto';
import { Usuario } from '@prisma/client';
import * as bcrypt from 'bcrypt';

type UsuarioSinPassword = Omit<Usuario, 'passwordHash'>;

@Injectable()
export class UsuariosService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Creates a new user after hashing the password.
   */
  async create(dto: CreateUsuarioDto): Promise<UsuarioSinPassword> {
    const existing = await this.prisma.usuario.findUnique({
      where: { email: dto.email },
    });
    if (existing) {
      throw new ConflictException('El email ya está registrado');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const usuario = await this.prisma.usuario.create({
      data: {
        email: dto.email,
        passwordHash,
        nombre: dto.nombre,
        telefono: dto.telefono,
      },
    });

    const { passwordHash: _pw, ...result } = usuario;
    return result;
  }

  /**
   * Returns one user by ID (without password).
   */
  async findOne(id: string): Promise<UsuarioSinPassword> {
    const usuario = await this.prisma.usuario.findUnique({ where: { id } });
    if (!usuario) throw new NotFoundException('Usuario no encontrado');
    const { passwordHash: _pw, ...result } = usuario;
    return result;
  }

  /**
   * Busca usuarios cuyo correo contenga el texto dado (coincidencia parcial,
   * insensible a mayúsculas). Devuelve solo campos públicos.
   */
  async buscarUsuarios(query: string) {
    const q = query.trim().toLowerCase();
    if (q.length < 2) return [];

    return this.prisma.usuario.findMany({
      where: { email: { contains: q, mode: 'insensitive' } },
      select: {
        id: true,
        nombre: true,
        email: true,
        telefono: true,
        fotoPerfil: true,
      },
      orderBy: { email: 'asc' },
      take: 10,
    });
  }

  /**
   * Updates nombre and/or telefono.
   */
  async update(id: string, dto: UpdateUsuarioDto): Promise<UsuarioSinPassword> {
    await this.findOne(id); // ensure exists

    const usuario = await this.prisma.usuario.update({
      where: { id },
      data: { ...dto },
    });

    const { passwordHash: _pw, ...result } = usuario;
    return result;
  }

  /**
   * Saves the relative path of the uploaded profile photo.
   */
  async updateFotoPerfil(id: string, relativePath: string): Promise<UsuarioSinPassword> {
    await this.findOne(id); // ensure exists

    const usuario = await this.prisma.usuario.update({
      where: { id },
      data: { fotoPerfil: relativePath },
    });

    const { passwordHash: _pw, ...result } = usuario;
    return result;
  }
}
