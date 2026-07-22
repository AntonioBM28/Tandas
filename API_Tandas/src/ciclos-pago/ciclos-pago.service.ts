import { Injectable, NotFoundException } from '@nestjs/common';
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

  async findByTanda(tandaId: string): Promise<CicloPago[]> {
    return this.prisma.cicloPago.findMany({
      where: { tandaId },
      include: { pagos: true, turnoBeneficiario: { include: { usuario: true } } },
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
