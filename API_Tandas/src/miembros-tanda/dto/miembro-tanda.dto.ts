import { IsOptional, IsEnum } from 'class-validator';
import { RolTanda, EstadoMiembro } from '@prisma/client';

// La gestión de turnos (asignar/quitar) vive en el módulo de tandas
// (PATCH /tandas/:id/asignar-turno, DELETE /tandas/:id/turnos/:turnoId),
// ya que un miembro puede tener varios turnos y este endpoint solo edita
// la fila de membresía en sí (estado y rol).
export class UpdateMiembroTandaDto {
  @IsOptional()
  @IsEnum(EstadoMiembro)
  estado?: EstadoMiembro;

  @IsOptional()
  @IsEnum(RolTanda)
  rol?: RolTanda;
}
