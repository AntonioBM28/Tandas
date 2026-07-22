import { IsString, IsDateString, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateCicloPagoDto {
  @IsString()
  tandaId!: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  numeroCiclo!: number;

  @IsDateString()
  fechaLimite!: string;

  @IsString()
  turnoBeneficiarioId!: string;
}
