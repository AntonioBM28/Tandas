import { IsEnum, IsOptional } from 'class-validator';
import { TipoDispositivo } from '@prisma/client';

export class GenerarCodigoDispositivoDto {
  // Opcional y por defecto RELOJ: el reloj ya llama este endpoint sin body
  // y debe seguir funcionando igual.
  @IsOptional()
  @IsEnum(TipoDispositivo, { message: 'tipoDispositivo debe ser RELOJ o TV' })
  tipoDispositivo?: TipoDispositivo;
}
