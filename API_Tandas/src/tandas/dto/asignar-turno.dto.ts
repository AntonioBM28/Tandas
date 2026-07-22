import { IsString, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class AsignarTurnoDto {
  @IsString({ message: 'El id del miembro es obligatorio' })
  miembroTandaId!: string;

  @Type(() => Number)
  @IsInt()
  @Min(1, { message: 'El turno debe ser mayor o igual a 1' })
  turnoOrden!: number;
}
