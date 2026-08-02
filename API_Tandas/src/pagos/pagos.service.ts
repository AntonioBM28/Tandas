import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePagoDto, UpdatePagoDto } from './dto/pago.dto';
import { Pago, EstadoPago } from '@prisma/client';

@Injectable()
export class PagosService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreatePagoDto): Promise<Pago> {
    return this.prisma.pago.create({
      data: {
        cicloPagoId: dto.cicloPagoId,
        miembroTandaId: dto.miembroTandaId,
        turnoTandaId: dto.turnoTandaId,
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

  async update(id: string, dto: UpdatePagoDto, usuarioId: string): Promise<Pago> {
    const pago = await this.prisma.pago.findUnique({
      where: { id },
      include: {
        cicloPago: { include: { tanda: true } },
        miembroTanda: true,
      },
    });
    if (!pago) throw new NotFoundException('Pago no encontrado');

    const esAdmin = pago.cicloPago.tanda.adminId === usuarioId;
    const esDueño = pago.miembroTanda.usuarioId === usuarioId;

    if (!esAdmin && !esDueño) {
      throw new ForbiddenException('No tienes permiso para actualizar este pago');
    }

    // El dueño del pago solo puede "reportar" que ya pagó; confirmarlo como
    // PAGADO (o cualquier otro cambio de estado) es exclusivo del admin.
    if (dto.estado && dto.estado !== EstadoPago.REPORTADO && !esAdmin) {
      throw new ForbiddenException(
        'Solo el administrador puede confirmar o modificar el estado de este pago',
      );
    }

    if (dto.estado === EstadoPago.REPORTADO && pago.estado === EstadoPago.PAGADO) {
      throw new BadRequestException('Este pago ya fue confirmado por el administrador');
    }

    return this.prisma.pago.update({
      where: { id },
      data: {
        estado: dto.estado,
        fechaPago: dto.fechaPago ? new Date(dto.fechaPago) : undefined,
      },
    });
  }
}
