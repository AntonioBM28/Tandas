import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCicloPagoDto } from './dto/create-ciclo-pago.dto';
import { CicloPago } from '@prisma/client';

@Injectable()
export class CiclosPagoService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateCicloPagoDto): Promise<CicloPago> {
    return this.prisma.cicloPago.create({
      data: {
        tandaId: dto.tandaId,
        numeroCiclo: dto.numeroCiclo,
        fechaLimite: new Date(dto.fechaLimite),
        turnoBeneficiarioId: dto.turnoBeneficiarioId,
      },
    });
  }

  async findByTanda(tandaId: string, usuarioId: string): Promise<CicloPago[]> {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id: tandaId },
      include: { miembros: { select: { usuarioId: true } } },
    });
    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    const isMember = tanda.miembros.some((m) => m.usuarioId === usuarioId);
    if (!isMember && tanda.adminId !== usuarioId) {
      throw new ForbiddenException('No tienes acceso a los ciclos de esta tanda');
    }

    return this.prisma.cicloPago.findMany({
      where: { tandaId },
      include: {
        turnoBeneficiario: {
          include: {
            usuario: { select: { id: true, nombre: true, fotoPerfil: true } },
          },
        },
        pagos: {
          include: {
            miembroTanda: {
              include: {
                usuario: { select: { id: true, nombre: true, fotoPerfil: true } },
              },
            },
          },
        },
      },
      orderBy: { numeroCiclo: 'asc' },
    });
  }

  async findOne(id: string): Promise<CicloPago> {
    const ciclo = await this.prisma.cicloPago.findUnique({
      where: { id },
      include: { pagos: true },
    });
    if (!ciclo) throw new NotFoundException('Ciclo de pago no encontrado');
    return ciclo;
  }
}
