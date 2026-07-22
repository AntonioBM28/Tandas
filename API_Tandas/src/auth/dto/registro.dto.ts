import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  Matches,
} from 'class-validator';

export class RegistroDto {
  @IsEmail({}, { message: 'El email proporcionado no es válido' })
  email!: string;

  @IsString()
  @MinLength(8, { message: 'El password debe tener al menos 8 caracteres' })
  @Matches(/((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/, {
    message: 'El password debe contener al menos una mayúscula y un número',
  })
  password!: string;

  @IsString({ message: 'El nombre es obligatorio' })
  @MinLength(1, { message: 'El nombre no puede estar vacío' })
  nombre!: string;

  @IsOptional()
  @IsString()
  telefono?: string;
}
