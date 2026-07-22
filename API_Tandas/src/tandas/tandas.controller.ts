import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Query,
  ParseUUIDPipe,
} from '@nestjs/common';
import { TandasService } from './tandas.service';
import { CreateTandaDto } from './dto/create-tanda.dto';
import { UpdateTandaDto } from './dto/update-tanda.dto';
import { AsignarTurnoDto } from './dto/asignar-turno.dto';
import { AddMiembroDto } from './dto/add-miembro.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UsuarioActual } from '../auth/decorators/usuario-actual.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { EstadoTanda } from '@prisma/client';

@UseGuards(JwtAuthGuard)
@Controller('tandas')
export class TandasController {
  constructor(private readonly tandasService: TandasService) {}

  @Post()
  create(
    @UsuarioActual() usuario: JwtPayload,
    @Body() dto: CreateTandaDto,
  ) {
    return this.tandasService.create(dto, usuario.sub);
  }

  @Get('mis-tandas')
  findMisTandas(
    @UsuarioActual() usuario: JwtPayload,
    @Query('estado') estado?: EstadoTanda,
  ) {
    return this.tandasService.findAllMisTandas(usuario.sub, estado);
  }

  @Get(':id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.tandasService.findOne(id, usuario.sub);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateTandaDto,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.tandasService.update(id, dto, usuario.sub);
  }

  @Delete(':id')
  cancelar(
    @Param('id', ParseUUIDPipe) id: string,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.tandasService.cancelar(id, usuario.sub);
  }

  @Patch(':id/asignar-turno')
  asignarTurno(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AsignarTurnoDto,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.tandasService.asignarTurno(id, dto, usuario.sub);
  }

  @Patch(':id/activar')
  activar(
    @Param('id', ParseUUIDPipe) id: string,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.tandasService.activar(id, usuario.sub);
  }

  @Post(':id/miembros')
  addMiembro(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddMiembroDto,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.tandasService.addMiembro(id, dto, usuario.sub);
  }

  @Get(':id/miembros')
  getMiembros(
    @Param('id', ParseUUIDPipe) id: string,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.tandasService.getMiembros(id, usuario.sub);
  }

  @Delete(':id/miembros/:miembroTandaId')
  removeMiembro(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('miembroTandaId', ParseUUIDPipe) miembroTandaId: string,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.tandasService.removeMiembro(id, miembroTandaId, usuario.sub);
  }
}
