import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePagoDto, UpdatePagoDto } from './dto/pago.dto';
import { Pago } from '@prisma/client';

@Injectable()
export class PagosService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreatePagoDto): Promise<Pago> {
    return this.prisma.pago.create({
      data: {
        cicloPagoId: dto.cicloPagoId,
        miembroTandaId: dto.miembroTandaId,
        monto: dto.monto,
        fechaPago: dto.fechaPago ? new Date(dto.fechaPago) : null,
        estado: dto.estado,
      },
    });
  }

  async findByCiclo(cicloPagoId: string): Promise<Pago[]> {
    return this.prisma.pago.findMany({
      where: { cicloPagoId },
      include: { miembroTanda: { include: { usuario: true } } },
    });
  }

  async findOne(id: string): Promise<Pago> {
    const pago = await this.prisma.pago.findUnique({ where: { id } });
    if (!pago) throw new NotFoundException('Pago no encontrado');
    return pago;
  }

  async update(id: string, dto: UpdatePagoDto): Promise<Pago> {
    await this.findOne(id);
    return this.prisma.pago.update({
      where: { id },
      data: {
        estado: dto.estado,
        fechaPago: dto.fechaPago ? new Date(dto.fechaPago) : undefined,
      },
    });
  }
}
