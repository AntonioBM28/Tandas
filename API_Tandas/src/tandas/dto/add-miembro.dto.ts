import { IsEmail } from 'class-validator';

export class AddMiembroDto {
  @IsEmail({}, { message: 'Debe ser un correo electrónico válido' })
  email!: string;
}
