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
import { PagosService } from './pagos.service';
import { CreatePagoDto, UpdatePagoDto } from './dto/pago.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('pagos')
export class PagosController {
  constructor(private readonly pagosService: PagosService) {}

  @Post()
  create(@Body() dto: CreatePagoDto) {
    return this.pagosService.create(dto);
  }

  @Get('ciclo/:cicloPagoId')
  findByCiclo(@Param('cicloPagoId', ParseUUIDPipe) cicloPagoId: string) {
    return this.pagosService.findByCiclo(cicloPagoId);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.pagosService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id', ParseUUIDPipe) id: string, @Body() dto: UpdatePagoDto) {
    return this.pagosService.update(id, dto);
  }
}
