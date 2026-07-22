import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  MaxLength,
} from 'class-validator';

export class CreateUsuarioDto {
  @IsEmail({}, { message: 'El email no es válido' })
  email!: string;

  @IsString()
  @MinLength(6, { message: 'La contraseña debe tener al menos 6 caracteres' })
  @MaxLength(100)
  password!: string;

  @IsString()
  @MinLength(2, { message: 'El nombre debe tener al menos 2 caracteres' })
  @MaxLength(100)
  nombre!: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  telefono?: string;
}
