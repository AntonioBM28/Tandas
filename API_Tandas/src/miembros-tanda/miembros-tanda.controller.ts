import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { MiembrosTandaService } from './miembros-tanda.service';
import { UpdateMiembroTandaDto } from './dto/miembro-tanda.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UsuarioActual } from '../auth/decorators/usuario-actual.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';

@UseGuards(JwtAuthGuard)
@Controller('miembros-tanda')
export class MiembrosTandaController {
  constructor(private readonly miembrosTandaService: MiembrosTandaService) {}



  @Get('tanda/:tandaId')
  findByTanda(
    @Param('tandaId', ParseUUIDPipe) tandaId: string,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.miembrosTandaService.findByTanda(tandaId, usuario.sub);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.miembrosTandaService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateMiembroTandaDto,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.miembrosTandaService.update(id, dto, usuario.sub);
  }
}
