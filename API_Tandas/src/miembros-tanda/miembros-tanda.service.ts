import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateMiembroTandaDto } from './dto/miembro-tanda.dto';
import { EstadoTanda, EstadoMiembro } from '@prisma/client';

@Injectable()
export class MiembrosTandaService {
  constructor(private readonly prisma: PrismaService) {}



  async findByTanda(tandaId: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id: tandaId },
      include: { miembros: true },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    const isMember = tanda.miembros.some((m) => m.usuarioId === usuarioId);
    if (!isMember && tanda.adminId !== usuarioId) {
      throw new ForbiddenException('No tienes acceso a esta tanda');
    }

    return tanda.miembros;
  }

  async findOne(id: string) {
    const miembro = await this.prisma.miembroTanda.findUnique({ where: { id } });
    if (!miembro) throw new NotFoundException('Miembro no encontrado');
    return miembro;
  }

  async update(id: string, dto: UpdateMiembroTandaDto, adminId: string) {
    const miembro = await this.prisma.miembroTanda.findUnique({
      where: { id },
      include: { tanda: true },
    });

    if (!miembro) throw new NotFoundException('Miembro no encontrado');
    
    if (miembro.tanda.adminId !== adminId) {
      throw new ForbiddenException('Solo el administrador de la tanda puede editar al miembro');
    }

    return this.prisma.miembroTanda.update({
      where: { id },
      data: dto,
    });
  }
}
