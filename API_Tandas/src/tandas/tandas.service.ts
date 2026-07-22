import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTandaDto } from './dto/create-tanda.dto';
import { UpdateTandaDto } from './dto/update-tanda.dto';
import { AsignarTurnoDto } from './dto/asignar-turno.dto';
import { AddMiembroDto } from './dto/add-miembro.dto';
import { Tanda, EstadoTanda, FrecuenciaTanda, EstadoMiembro } from '@prisma/client';
import { Prisma } from '@prisma/client';

@Injectable()
export class TandasService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * 1. POST /tandas (crear tanda)
   */
  async create(dto: CreateTandaDto, adminId: string): Promise<Tanda> {
    return this.prisma.$transaction(async (tx) => {
      // Create Tanda
      const tanda = await tx.tanda.create({
        data: {
          nombre: dto.nombre,
          descripcion: dto.descripcion,
          montoAportacion: dto.montoAportacion,
          frecuencia: dto.frecuencia,
          numParticipantes: dto.numParticipantes,
          estado: EstadoTanda.ARMANDO,
          fechaInicio: null,
          adminId,
        },
      });

      // Create Admin MiembroTanda
      await tx.miembroTanda.create({
        data: {
          tandaId: tanda.id,
          usuarioId: adminId,
          rol: 'ADMIN',
          turnoOrden: 1,
          estado: 'ACTIVO',
        },
      });

      // Return with members included
      return tx.tanda.findUniqueOrThrow({
        where: { id: tanda.id },
        include: { miembros: true },
      });
    });
  }

  /**
   * 2. GET /tandas/mis-tandas
   */
  async findAllMisTandas(usuarioId: string, estado?: EstadoTanda) {
    const tandas = await this.prisma.tanda.findMany({
      where: {
        miembros: {
          some: { usuarioId },
        },
        ...(estado && { estado }),
      },
      include: {
        _count: {
          select: { miembros: true },
        },
        miembros: {
          where: { usuarioId },
          select: { rol: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return tandas.map((t) => ({
      ...t,
      miembros: undefined, // remove full array to clean response
      miRol: t.miembros[0]?.rol,
      numMiembrosActuales: t._count.miembros,
    }));
  }

  /**
   * 3. GET /tandas/:id
   */
  async findOne(id: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id },
      include: {
        miembros: {
          include: {
            usuario: {
              select: { id: true, nombre: true, fotoPerfil: true, email: true },
            },
          },
          orderBy: { turnoOrden: 'asc' },
        },
        ciclos: {
          orderBy: { numeroCiclo: 'asc' },
        },
      },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    // Verify user is member
    const isMember = tanda.miembros.some((m) => m.usuarioId === usuarioId);
    if (!isMember && tanda.adminId !== usuarioId) {
      throw new ForbiddenException('No tienes acceso a esta tanda');
    }

    return tanda;
  }

  /**
   * 4. PATCH /tandas/:id
   */
  async update(id: string, dto: UpdateTandaDto, usuarioId: string): Promise<Tanda> {
    const tanda = await this.prisma.tanda.findUnique({ where: { id } });
    if (!tanda) throw new NotFoundException('Tanda no encontrada');
    
    if (tanda.adminId !== usuarioId) {
      throw new ForbiddenException('Solo el administrador puede editar la tanda');
    }

    if (
      (tanda.estado === EstadoTanda.ACTIVA || tanda.estado === EstadoTanda.FINALIZADA) &&
      (dto.montoAportacion !== undefined || dto.numParticipantes !== undefined)
    ) {
      throw new BadRequestException(
        'No se puede modificar el monto ni los participantes porque la tanda ya está activa o finalizada',
      );
    }

    return this.prisma.tanda.update({
      where: { id },
      data: dto,
    });
  }

  /**
   * 5. DELETE /tandas/:id
   */
  async cancelar(id: string, usuarioId: string): Promise<Tanda> {
    const tanda = await this.prisma.tanda.findUnique({ where: { id } });
    if (!tanda) throw new NotFoundException('Tanda no encontrada');
    
    if (tanda.adminId !== usuarioId) {
      throw new ForbiddenException('Solo el administrador puede cancelar la tanda');
    }

    if (tanda.estado === EstadoTanda.FINALIZADA || tanda.estado === EstadoTanda.CANCELADA) {
      throw new BadRequestException('La tanda ya está finalizada o cancelada');
    }

    return this.prisma.tanda.update({
      where: { id },
      data: { estado: EstadoTanda.CANCELADA },
    });
  }

  /**
   * 6. PATCH /tandas/:id/asignar-turno
   */
  async asignarTurno(id: string, dto: AsignarTurnoDto, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({ where: { id } });
    if (!tanda) throw new NotFoundException('Tanda no encontrada');
    
    if (tanda.adminId !== usuarioId) {
      throw new ForbiddenException('Solo el administrador puede asignar turnos');
    }

    if (dto.turnoOrden < 1 || dto.turnoOrden > tanda.numParticipantes) {
      throw new BadRequestException(
        `El turno debe estar entre 1 y ${tanda.numParticipantes}`,
      );
    }

    const miembro = await this.prisma.miembroTanda.findFirst({
      where: { id: dto.miembroTandaId, tandaId: id },
    });

    if (!miembro) {
      throw new NotFoundException('El miembro no pertenece a esta tanda');
    }

    try {
      return await this.prisma.miembroTanda.update({
        where: { id: dto.miembroTandaId },
        data: { turnoOrden: dto.turnoOrden },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2002') {
          throw new BadRequestException(`El turno ${dto.turnoOrden} ya está asignado a otro miembro`);
        }
      }
      throw error;
    }
  }

  /**
   * 7. PATCH /tandas/:id/activar
   */
  async activar(id: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id },
      include: { miembros: true },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');
    
    if (tanda.adminId !== usuarioId) {
      throw new ForbiddenException('Solo el administrador puede activar la tanda');
    }

    if (tanda.estado !== EstadoTanda.ARMANDO) {
      throw new BadRequestException('La tanda no está en estado ARMANDO');
    }

    const activos = tanda.miembros.filter((m) => m.estado === 'ACTIVO');
    
    // a. Validate member count
    if (activos.length !== tanda.numParticipantes) {
      const faltan = tanda.numParticipantes - activos.length;
      throw new BadRequestException(`Faltan ${faltan} miembros activos para poder iniciar la tanda`);
    }

    // b. Validate all active members have turnos
    const sinTurno = activos.filter((m) => m.turnoOrden === null);
    if (sinTurno.length > 0) {
      const nombresFaltantes = sinTurno.map(m => m.id).join(', '); // En la vida real cruzaríamos con el Usuario
      throw new BadRequestException(`Los siguientes miembros no tienen turno asignado: ${nombresFaltantes}`);
    }

    const turnoUno = activos.find((m) => m.turnoOrden === 1);
    if (!turnoUno) {
      throw new BadRequestException('Nadie tiene asignado el turno 1');
    }

    return this.prisma.$transaction(async (tx) => {
      const fechaInicio = new Date();
      
      // Update Tanda
      const tandaActualizada = await tx.tanda.update({
        where: { id },
        data: {
          estado: EstadoTanda.ACTIVA,
          fechaInicio,
        },
      });

      // Generate Primer Ciclo
      let dias = 7;
      if (tanda.frecuencia === FrecuenciaTanda.QUINCENAL) dias = 15;
      if (tanda.frecuencia === FrecuenciaTanda.MENSUAL) dias = 30;

      const fechaLimite = new Date(fechaInicio);
      fechaLimite.setDate(fechaLimite.getDate() + dias);

      const primerCiclo = await tx.cicloPago.create({
        data: {
          tandaId: id,
          numeroCiclo: 1,
          turnoBeneficiarioId: turnoUno.id,
          fechaLimite,
        },
      });

      // Generate Pagos for all active members
      const pagosData = activos.map((m) => ({
        cicloPagoId: primerCiclo.id,
        miembroTandaId: m.id,
        monto: tanda.montoAportacion,
        estado: 'PENDIENTE' as const,
      }));

      await tx.pago.createMany({
        data: pagosData,
      });

      return tx.tanda.findUnique({
        where: { id },
        include: {
          ciclos: {
            include: { pagos: true },
          },
        },
      });
    });
  }

  /**
   * 8. POST /tandas/:id/miembros
   */
  async addMiembro(tandaId: string, dto: AddMiembroDto, adminId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id: tandaId },
      include: { miembros: { where: { estado: EstadoMiembro.ACTIVO } } },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    if (tanda.adminId !== adminId) {
      throw new ForbiddenException('Solo el administrador puede agregar miembros');
    }

    if (tanda.estado !== EstadoTanda.ARMANDO) {
      throw new BadRequestException('Solo se pueden agregar miembros cuando la tanda está en estado ARMANDO');
    }

    if (tanda.miembros.length >= tanda.numParticipantes) {
      throw new BadRequestException('La tanda ya está llena');
    }

    const usuario = await this.prisma.usuario.findUnique({
      where: { email: dto.email },
    });

    if (!usuario) {
      throw new NotFoundException('El usuario debe registrarse en la app antes de poder ser agregado');
    }

    const existe = tanda.miembros.some((m) => m.usuarioId === usuario.id);
    if (existe) {
      throw new ConflictException('Este usuario ya es miembro de la tanda');
    }

    return this.prisma.miembroTanda.create({
      data: {
        tandaId,
        usuarioId: usuario.id,
        rol: 'MIEMBRO',
        turnoOrden: null,
        estado: EstadoMiembro.ACTIVO,
      },
      include: {
        usuario: { select: { id: true, nombre: true, email: true, fotoPerfil: true } },
      },
    });
  }

  /**
   * 9. GET /tandas/:id/miembros
   */
  async getMiembros(tandaId: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id: tandaId },
      include: {
        miembros: {
          where: { estado: EstadoMiembro.ACTIVO },
          include: {
            usuario: { select: { id: true, nombre: true, email: true, fotoPerfil: true } },
          },
        },
      },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    const isMember = tanda.miembros.some((m) => m.usuarioId === usuarioId);
    if (!isMember && tanda.adminId !== usuarioId) {
      throw new ForbiddenException('No tienes acceso a los miembros de esta tanda');
    }

    return tanda.miembros.sort((a, b) => {
      if (a.turnoOrden === null && b.turnoOrden === null) return 0;
      if (a.turnoOrden === null) return 1;
      if (b.turnoOrden === null) return -1;
      return a.turnoOrden - b.turnoOrden;
    });
  }

  /**
   * 10. DELETE /tandas/:id/miembros/:miembroTandaId
   */
  async removeMiembro(tandaId: string, miembroTandaId: string, adminId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id: tandaId },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    if (tanda.adminId !== adminId) {
      throw new ForbiddenException('Solo el administrador puede quitar miembros');
    }

    if (tanda.estado !== EstadoTanda.ARMANDO) {
      throw new BadRequestException('No se puede quitar a nadie porque la tanda ya inició y rompería los ciclos generados');
    }

    const miembro = await this.prisma.miembroTanda.findFirst({
      where: { id: miembroTandaId, tandaId },
    });

    if (!miembro) throw new NotFoundException('Miembro no encontrado en esta tanda');

    if (miembro.usuarioId === adminId) {
      throw new BadRequestException('No puedes expulsarte a ti mismo de tu propia tanda');
    }

    return this.prisma.miembroTanda.update({
      where: { id: miembroTandaId },
      data: {
        estado: EstadoMiembro.EXPULSADO,
        turnoOrden: null,
      },
    });
  }
}
