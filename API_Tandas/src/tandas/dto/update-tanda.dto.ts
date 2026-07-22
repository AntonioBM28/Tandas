import {
  IsString,
  IsOptional,
  IsEnum,
  IsInt,
  IsPositive,
  Min,
  MaxLength,
} from 'class-validator';
import { FrecuenciaTanda } from '@prisma/client';
import { Type } from 'class-transformer';

export class UpdateTandaDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  nombre?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  descripcion?: string;

  @IsOptional()
  @Type(() => Number)
  @IsPositive()
  montoAportacion?: number;

  @IsOptional()
  @IsEnum(FrecuenciaTanda)
  frecuencia?: FrecuenciaTanda;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2)
  numParticipantes?: number;
}
