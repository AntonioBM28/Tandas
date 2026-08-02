import {
  IsString,
  IsOptional,
  IsEnum,
  IsInt,
  IsPositive,
  IsBoolean,
  Min,
  MaxLength,
} from 'class-validator';
import { FrecuenciaTanda } from '@prisma/client';
import { Type } from 'class-transformer';

export class CreateTandaDto {
  @IsString({ message: 'El nombre es obligatorio' })
  @MaxLength(100)
  nombre!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  descripcion?: string;

  @Type(() => Number)
  @IsPositive({ message: 'El monto de aportación debe ser positivo' })
  montoAportacion!: number;

  @IsEnum(FrecuenciaTanda, {
    message: 'La frecuencia debe ser SEMANAL, QUINCENAL o MENSUAL',
  })
  frecuencia!: FrecuenciaTanda;

  @Type(() => Number)
  @IsInt()
  @Min(2, { message: 'Debe haber al menos 2 participantes' })
  numParticipantes!: number;

  @IsOptional()
  @IsBoolean({ message: 'unirseComoMiembro debe ser verdadero o falso' })
  unirseComoMiembro?: boolean;
}
