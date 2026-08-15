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

      // El admin solo se vuelve participante (con turno) si lo decide explícitamente;
      // por defecto puede administrar la tanda sin ocupar un lugar en la rotación.
      if (dto.unirseComoMiembro) {
        const miembroAdmin = await tx.miembroTanda.create({
          data: {
            tandaId: tanda.id,
            usuarioId: adminId,
            rol: 'ADMIN',
            estado: 'ACTIVO',
          },
        });

        await tx.turnoTanda.create({
          data: {
            tandaId: tanda.id,
            turnoOrden: 1,
            miembroTandaId: miembroAdmin.id,
          },
        });
      }

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
        OR: [
          { adminId: usuarioId },
          { miembros: { some: { usuarioId, estado: EstadoMiembro.ACTIVO } } },
        ],
        ...(estado && { estado }),
      },
      include: {
        // Solo contamos/miramos membresías ACTIVAS: si alguien salió o fue
        // expulsado, su fila sigue existiendo pero no debe seguir
        // apareciendo en "mis tandas" ni contar en el total de miembros.
        _count: {
          select: { miembros: { where: { estado: EstadoMiembro.ACTIVO } } },
        },
        miembros: {
          where: { usuarioId, estado: EstadoMiembro.ACTIVO },
          select: { rol: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return tandas.map((t) => ({
      ...t,
      miembros: undefined, // remove full array to clean response
      // El admin siempre se muestra como ADMIN, aunque no tenga fila de membresía
      // (o incluso si se unió después con rol MIEMBRO en esa fila).
      miRol: t.adminId === usuarioId ? 'ADMIN' : t.miembros[0]?.rol,
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
            turnos: { orderBy: { turnoOrden: 'asc' } },
          },
          orderBy: { fechaUnion: 'asc' },
        },
        ciclos: {
          orderBy: { numeroCiclo: 'asc' },
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
                turnoTanda: true,
              },
            },
          },
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
   * 3b. GET /tandas/:id/pantalla-publica
   * Vista resumida pensada para una pantalla grande (TV) durante una
   * reunión: solo el ciclo vigente y quién ya pagó, sin arrastrar el
   * historial completo de ciclos que sí trae la vista de detalle normal.
   */
  async pantallaPublica(id: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id },
      include: {
        miembros: { select: { usuarioId: true } },
        ciclos: {
          orderBy: { numeroCiclo: 'desc' },
          take: 1,
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
        },
      },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    const isMember = tanda.miembros.some((m) => m.usuarioId === usuarioId);
    if (!isMember && tanda.adminId !== usuarioId) {
      throw new ForbiddenException('No tienes acceso a esta tanda');
    }

    const cicloActual = tanda.ciclos[0] ?? null;

    return {
      tanda: {
        id: tanda.id,
        nombre: tanda.nombre,
        montoAportacion: tanda.montoAportacion,
        frecuencia: tanda.frecuencia,
        numParticipantes: tanda.numParticipantes,
        estado: tanda.estado,
      },
      cicloActual: cicloActual && {
        numeroCiclo: cicloActual.numeroCiclo,
        fechaLimite: cicloActual.fechaLimite,
        cerrado: cicloActual.cerrado,
        montoTotalCiclo: tanda.numParticipantes * Number(tanda.montoAportacion),
        beneficiario: cicloActual.turnoBeneficiario.usuario,
        pagos: cicloActual.pagos.map((p) => ({
          miembroTandaId: p.miembroTandaId,
          nombre: p.miembroTanda.usuario.nombre,
          fotoPerfil: p.miembroTanda.usuario.fotoPerfil,
          estado: p.estado,
          monto: p.monto,
        })),
        resumen: {
          total: cicloActual.pagos.length,
          pagados: cicloActual.pagos.filter((p) => p.estado === 'PAGADO').length,
          reportados: cicloActual.pagos.filter((p) => p.estado === 'REPORTADO').length,
          pendientes: cicloActual.pagos.filter((p) => p.estado === 'PENDIENTE').length,
          atrasados: cicloActual.pagos.filter((p) => p.estado === 'ATRASADO').length,
        },
      },
    };
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
   * Le agrega UN turno adicional al miembro indicado (un miembro puede
   * terminar con varios turnos si se llama repetidas veces).
   */
  async asignarTurno(id: string, dto: AsignarTurnoDto, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({ where: { id } });
    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    if (tanda.adminId !== usuarioId) {
      throw new ForbiddenException('Solo el administrador puede asignar turnos');
    }

    if (tanda.estado !== EstadoTanda.ARMANDO) {
      throw new BadRequestException('Solo se pueden asignar turnos mientras la tanda está en armado');
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
      return await this.prisma.turnoTanda.create({
        data: {
          tandaId: id,
          turnoOrden: dto.turnoOrden,
          miembroTandaId: dto.miembroTandaId,
        },
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
   * 6b. DELETE /tandas/:id/turnos/:turnoTandaId
   * Libera un turno específico (útil cuando un miembro tiene varios y solo
   * quieres corregir/quitar uno).
   */
  async quitarTurno(id: string, turnoTandaId: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({ where: { id } });
    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    if (tanda.adminId !== usuarioId) {
      throw new ForbiddenException('Solo el administrador puede quitar turnos');
    }

    if (tanda.estado !== EstadoTanda.ARMANDO) {
      throw new BadRequestException('Solo se pueden quitar turnos mientras la tanda está en armado');
    }

    const turno = await this.prisma.turnoTanda.findFirst({
      where: { id: turnoTandaId, tandaId: id },
    });

    if (!turno) throw new NotFoundException('Turno no encontrado en esta tanda');

    return this.prisma.turnoTanda.delete({ where: { id: turnoTandaId } });
  }

  /**
   * 7. PATCH /tandas/:id/activar
   */
  async activar(id: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id },
      include: { miembros: { include: { turnos: true } } },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    if (tanda.adminId !== usuarioId) {
      throw new ForbiddenException('Solo el administrador puede activar la tanda');
    }

    if (tanda.estado !== EstadoTanda.ARMANDO) {
      throw new BadRequestException('La tanda no está en estado ARMANDO');
    }

    const activos = tanda.miembros.filter((m) => m.estado === 'ACTIVO');

    // a. Todo miembro activo debe tener al menos un turno (si no, no aporta
    //    ni cobra nunca: no tiene sentido que esté "adentro" sin turno).
    const sinTurno = activos.filter((m) => m.turnos.length === 0);
    if (sinTurno.length > 0) {
      throw new BadRequestException(
        `Hay ${sinTurno.length} miembro(s) activo(s) sin ningún turno asignado`,
      );
    }

    // b. Los turnos asignados (contando repetidos por miembro) deben cubrir
    //    exactamente 1..numParticipantes, sin huecos ni sobrantes.
    const todosLosTurnos = activos.flatMap((m) => m.turnos);
    if (todosLosTurnos.length !== tanda.numParticipantes) {
      const faltan = tanda.numParticipantes - todosLosTurnos.length;
      throw new BadRequestException(
        faltan > 0
          ? `Faltan ${faltan} turno(s) por asignar para completar la tanda`
          : `Hay más turnos asignados (${todosLosTurnos.length}) que participantes (${tanda.numParticipantes})`,
      );
    }

    const ordenes = todosLosTurnos.map((t) => t.turnoOrden).sort((a, b) => a - b);
    for (let i = 0; i < ordenes.length; i++) {
      if (ordenes[i] !== i + 1) {
        throw new BadRequestException(
          `Los turnos deben cubrir del 1 al ${tanda.numParticipantes} sin huecos (falta el turno ${i + 1})`,
        );
      }
    }

    const turnoUno = todosLosTurnos.find((t) => t.turnoOrden === 1)!;

    return this.prisma.$transaction(async (tx) => {
      const fechaInicio = new Date();

      // Update Tanda
      await tx.tanda.update({
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
          turnoBeneficiarioId: turnoUno.miembroTandaId,
          fechaLimite,
        },
      });

      // Una aportación por cada turno (no por cada miembro): quien tiene
      // más de un turno aporta y cobra proporcionalmente más veces.
      // Excepción: el turno beneficiario de este ciclo no aporta su propia
      // parte, ya que de todas formas va a recibir el bote completo.
      const pagosData = activos.flatMap((m) =>
        m.turnos
          .filter((t) => t.id !== turnoUno.id)
          .map((t) => ({
            cicloPagoId: primerCiclo.id,
            miembroTandaId: m.id,
            turnoTandaId: t.id,
            monto: tanda.montoAportacion,
            estado: 'PENDIENTE' as const,
          })),
      );

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
   * 7b. PATCH /tandas/:id/avanzar-ciclo
   * Cierra el ciclo actual (requiere que todos sus pagos estén PAGADO, para
   * que el beneficiario haya recibido el bote completo) y genera el
   * siguiente. Si ya se completó una vuelta entera (turno numParticipantes),
   * la tanda pasa a FINALIZADA en vez de generar un ciclo nuevo.
   */
  async avanzarCiclo(id: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id },
      include: {
        miembros: { where: { estado: EstadoMiembro.ACTIVO }, include: { turnos: true } },
        ciclos: {
          orderBy: { numeroCiclo: 'desc' },
          take: 1,
          include: { pagos: true },
        },
      },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    if (tanda.adminId !== usuarioId) {
      throw new ForbiddenException('Solo el administrador puede avanzar de ciclo');
    }

    if (tanda.estado !== EstadoTanda.ACTIVA) {
      throw new BadRequestException('La tanda no está activa');
    }

    const cicloActual = tanda.ciclos[0];
    if (!cicloActual) {
      throw new BadRequestException('Esta tanda todavía no tiene ningún ciclo generado');
    }

    if (cicloActual.cerrado) {
      throw new BadRequestException('El ciclo actual ya está cerrado');
    }

    const pendientes = cicloActual.pagos.filter((p) => p.estado !== 'PAGADO');
    if (pendientes.length > 0) {
      throw new BadRequestException(
        `Faltan ${pendientes.length} pago(s) por marcar como pagado antes de avanzar de ciclo`,
      );
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.cicloPago.update({
        where: { id: cicloActual.id },
        data: { cerrado: true },
      });

      const siguienteNumero = cicloActual.numeroCiclo + 1;

      // Ya se completó una vuelta entera: no hay más turnos que pagar.
      if (siguienteNumero > tanda.numParticipantes) {
        return tx.tanda.update({
          where: { id },
          data: { estado: EstadoTanda.FINALIZADA },
        });
      }

      const turnos = tanda.miembros.flatMap((m) => m.turnos);
      const turnoBeneficiario = turnos.find((t) => t.turnoOrden === siguienteNumero);
      if (!turnoBeneficiario) {
        throw new BadRequestException(
          `Nadie tiene asignado el turno ${siguienteNumero}; no se puede generar el siguiente ciclo`,
        );
      }

      let dias = 7;
      if (tanda.frecuencia === FrecuenciaTanda.QUINCENAL) dias = 15;
      if (tanda.frecuencia === FrecuenciaTanda.MENSUAL) dias = 30;

      const fechaLimite = new Date(cicloActual.fechaLimite);
      fechaLimite.setDate(fechaLimite.getDate() + dias);

      const nuevoCiclo = await tx.cicloPago.create({
        data: {
          tandaId: id,
          numeroCiclo: siguienteNumero,
          turnoBeneficiarioId: turnoBeneficiario.miembroTandaId,
          fechaLimite,
        },
      });

      // El turno beneficiario de este ciclo no aporta su propia parte.
      const pagosData = tanda.miembros.flatMap((m) =>
        m.turnos
          .filter((t) => t.id !== turnoBeneficiario.id)
          .map((t) => ({
            cicloPagoId: nuevoCiclo.id,
            miembroTandaId: m.id,
            turnoTandaId: t.id,
            monto: tanda.montoAportacion,
            estado: 'PENDIENTE' as const,
          })),
      );

      await tx.pago.createMany({ data: pagosData });

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

    const turnos = dto.turnos ?? [];
    for (const turnoOrden of turnos) {
      if (turnoOrden < 1 || turnoOrden > tanda.numParticipantes) {
        throw new BadRequestException(
          `El turno debe estar entre 1 y ${tanda.numParticipantes}`,
        );
      }
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

    try {
      return await this.prisma.$transaction(async (tx) => {
        const miembro = await tx.miembroTanda.create({
          data: {
            tandaId,
            usuarioId: usuario.id,
            rol: 'MIEMBRO',
            estado: EstadoMiembro.ACTIVO,
          },
        });

        if (turnos.length > 0) {
          await tx.turnoTanda.createMany({
            data: turnos.map((turnoOrden) => ({
              tandaId,
              turnoOrden,
              miembroTandaId: miembro.id,
            })),
          });
        }

        return tx.miembroTanda.findUniqueOrThrow({
          where: { id: miembro.id },
          include: {
            usuario: { select: { id: true, nombre: true, email: true, fotoPerfil: true } },
            turnos: { orderBy: { turnoOrden: 'asc' } },
          },
        });
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2002') {
          throw new BadRequestException('Uno de los turnos seleccionados ya está asignado a otro miembro');
        }
      }
      throw error;
    }
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
            turnos: { orderBy: { turnoOrden: 'asc' } },
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
      const aMin = a.turnos[0]?.turnoOrden ?? Infinity;
      const bMin = b.turnos[0]?.turnoOrden ?? Infinity;
      return aMin - bMin;
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

    return this.prisma.$transaction(async (tx) => {
      // Libera todos los turnos que tenía, para que vuelvan a estar disponibles.
      await tx.turnoTanda.deleteMany({ where: { miembroTandaId } });

      return tx.miembroTanda.update({
        where: { id: miembroTandaId },
        data: {
          estado: EstadoMiembro.EXPULSADO,
        },
      });
    });
  }

  /**
   * 11. DELETE /tandas/:id/miembros/salir
   * Un miembro (no el admin) sale de la tanda por su cuenta. Solo mientras
   * está en ARMANDO, igual que removeMiembro, para no romper ciclos ya
   * generados.
   */
  async salirDeTanda(tandaId: string, usuarioId: string) {
    const tanda = await this.prisma.tanda.findUnique({
      where: { id: tandaId },
    });

    if (!tanda) throw new NotFoundException('Tanda no encontrada');

    if (tanda.adminId === usuarioId) {
      throw new BadRequestException(
        'Eres el administrador de esta tanda; para dejarla debes cancelarla',
      );
    }

    if (tanda.estado !== EstadoTanda.ARMANDO) {
      throw new BadRequestException(
        'Solo puedes salir de la tanda mientras todavía no ha iniciado',
      );
    }

    const miembro = await this.prisma.miembroTanda.findFirst({
      where: { tandaId, usuarioId, estado: EstadoMiembro.ACTIVO },
    });

    if (!miembro) {
      throw new NotFoundException('No eres miembro activo de esta tanda');
    }

    return this.prisma.$transaction(async (tx) => {
      // Libera todos los turnos que tenía, para que vuelvan a estar disponibles.
      await tx.turnoTanda.deleteMany({ where: { miembroTandaId: miembro.id } });

      return tx.miembroTanda.update({
        where: { id: miembro.id },
        // INACTIVO (no EXPULSADO): fue su propia decisión, no una expulsión.
        data: { estado: EstadoMiembro.INACTIVO },
      });
    });
  }
}
