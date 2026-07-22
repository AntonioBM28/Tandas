import { IsString, IsOptional, MaxLength, MinLength } from 'class-validator';

export class UpdateUsuarioDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  nombre?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  telefono?: string;
}
