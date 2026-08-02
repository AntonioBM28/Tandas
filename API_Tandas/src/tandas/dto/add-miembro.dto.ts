import { IsEmail, IsInt, IsOptional, IsArray, ArrayUnique, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class AddMiembroDto {
  @IsEmail({}, { message: 'Debe ser un correo electrónico válido' })
  email!: string;

  // Un miembro puede quedarse con varios turnos desde que se agrega
  // (ej. [1, 4] = ocupa el turno 1 y el turno 4).
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @Type(() => Number)
  @IsInt({ each: true })
  @Min(1, { each: true, message: 'Cada turno debe ser mayor o igual a 1' })
  turnos?: number[];
}
