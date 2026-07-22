import { IsEnum, IsOptional, IsBoolean } from 'class-validator';
import { TipoNotificacion } from '@prisma/client';

export class CreateNotificacionDto {
  @IsEnum(TipoNotificacion)
  tipo!: TipoNotificacion;

  usuarioId!: string;

  mensaje!: string;

  @IsOptional()
  metadata?: Record<string, unknown>;
}

export class UpdateNotificacionDto {
  @IsOptional()
  @IsBoolean()
  leido?: boolean;
}
