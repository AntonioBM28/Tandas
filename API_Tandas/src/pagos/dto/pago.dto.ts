import { IsString, IsOptional, IsEnum, IsDateString, IsPositive } from 'class-validator';
import { EstadoPago } from '@prisma/client';
import { Type } from 'class-transformer';

export class CreatePagoDto {
  @IsString()
  cicloPagoId!: string;

  @IsString()
  miembroTandaId!: string;

  @Type(() => Number)
  @IsPositive()
  monto!: number;

  @IsOptional()
  @IsDateString()
  fechaPago?: string;

  @IsOptional()
  @IsEnum(EstadoPago)
  estado?: EstadoPago;
}

export class UpdatePagoDto {
  @IsOptional()
  @IsEnum(EstadoPago)
  estado?: EstadoPago;

  @IsOptional()
  @IsDateString()
  fechaPago?: string;
}
