import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNotificacionDto } from './dto/notificacion.dto';
import { Notificacion } from '@prisma/client';

@Injectable()
export class NotificacionesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateNotificacionDto): Promise<Notificacion> {
    return this.prisma.notificacion.create({
      data: {
        usuarioId: dto.usuarioId,
        tipo: dto.tipo,
        mensaje: dto.mensaje,
        metadata: dto.metadata ? (dto.metadata as any) : undefined,
      },
    });
  }

  async findByUsuario(usuarioId: string, soloNoLeidas?: boolean): Promise<Notificacion[]> {
    return this.prisma.notificacion.findMany({
      where: {
        usuarioId,
        ...(soloNoLeidas ? { leido: false } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async marcarLeida(id: string, usuarioId: string): Promise<Notificacion> {
    const notif = await this.prisma.notificacion.findFirst({
      where: { id, usuarioId },
    });
    if (!notif) throw new NotFoundException('Notificación no encontrada');
    return this.prisma.notificacion.update({ where: { id }, data: { leido: true } });
  }

  async marcarTodasLeidas(usuarioId: string): Promise<{ count: number }> {
    const result = await this.prisma.notificacion.updateMany({
      where: { usuarioId, leido: false },
      data: { leido: true },
    });
    return { count: result.count };
  }
}
