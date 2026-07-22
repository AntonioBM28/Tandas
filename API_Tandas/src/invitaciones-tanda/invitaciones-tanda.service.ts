import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateInvitacionTandaDto } from './dto/invitacion-tanda.dto';
import { InvitacionTanda } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class InvitacionesTandaService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateInvitacionTandaDto, creadoPorId: string): Promise<InvitacionTanda> {
    const codigo = uuidv4().replace(/-/g, '').substring(0, 12).toUpperCase();

    return this.prisma.invitacionTanda.create({
      data: {
        tandaId: dto.tandaId,
        creadoPorId,
        codigo,
        usosMaximos: dto.usosMaximos ?? 1,
        expiraEn: dto.expiraEn ? new Date(dto.expiraEn) : null,
      },
    });
  }

  async findByCodigo(codigo: string): Promise<InvitacionTanda> {
    const inv = await this.prisma.invitacionTanda.findUnique({ where: { codigo } });
    if (!inv) throw new NotFoundException('Invitación no encontrada');
    return inv;
  }

  async findByTanda(tandaId: string): Promise<InvitacionTanda[]> {
    return this.prisma.invitacionTanda.findMany({ where: { tandaId } });
  }

  async cancelar(id: string): Promise<InvitacionTanda> {
    const inv = await this.prisma.invitacionTanda.findUnique({ where: { id } });
    if (!inv) throw new NotFoundException('Invitación no encontrada');
    if (inv.estado !== 'ACTIVA') {
      throw new BadRequestException('La invitación no está activa');
    }
    return this.prisma.invitacionTanda.update({
      where: { id },
      data: { estado: 'CANCELADA' },
    });
  }
}
