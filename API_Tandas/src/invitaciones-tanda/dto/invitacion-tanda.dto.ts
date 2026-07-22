import {
  IsString,
  IsOptional,
  IsInt,
  Min,
  IsDateString,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateInvitacionTandaDto {
  @IsString()
  tandaId!: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  usosMaximos?: number;

  @IsOptional()
  @IsDateString()
  expiraEn?: string;
}

export class UsarInvitacionDto {
  @IsString()
  codigo!: string;
}
