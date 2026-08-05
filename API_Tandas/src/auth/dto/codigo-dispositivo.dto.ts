import { IsString, Length, Matches } from 'class-validator';

export class ConfirmarCodigoDispositivoDto {
  @IsString()
  @Length(6, 6, { message: 'El código debe tener 6 dígitos' })
  @Matches(/^\d{6}$/, { message: 'El código debe ser numérico' })
  codigo!: string;
}
