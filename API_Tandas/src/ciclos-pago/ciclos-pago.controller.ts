import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { CiclosPagoService } from './ciclos-pago.service';
import { CreateCicloPagoDto } from './dto/create-ciclo-pago.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UsuarioActual } from '../auth/decorators/usuario-actual.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';

@UseGuards(JwtAuthGuard)
@Controller('ciclos-pago')
export class CiclosPagoController {
  constructor(private readonly ciclosPagoService: CiclosPagoService) {}

  @Post()
  create(@Body() dto: CreateCicloPagoDto) {
    return this.ciclosPagoService.create(dto);
  }

  @Get('tanda/:tandaId')
  findByTanda(
    @Param('tandaId', ParseUUIDPipe) tandaId: string,
    @UsuarioActual() usuario: JwtPayload,
  ) {
    return this.ciclosPagoService.findByTanda(tandaId, usuario.sub);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.ciclosPagoService.findOne(id);
  }
}
