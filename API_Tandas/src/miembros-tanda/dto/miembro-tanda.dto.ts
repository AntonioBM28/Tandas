import { IsString, IsOptional, IsEnum, IsInt, Min } from 'class-validator';
import { RolTanda, EstadoMiembro } from '@prisma/client';
import { Type } from 'class-transformer';


export class UpdateMiembroTandaDto {
  @IsOptional()
  @IsEnum(EstadoMiembro)
  estado?: EstadoMiembro;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  turnoOrden?: number;

  @IsOptional()
  @IsEnum(RolTanda)
  rol?: RolTanda;
}
