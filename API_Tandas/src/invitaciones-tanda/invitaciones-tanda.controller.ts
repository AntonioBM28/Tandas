import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
  ParseUUIDPipe,
} from '@nestjs/common';
import { InvitacionesTandaService } from './invitaciones-tanda.service';
import { CreateInvitacionTandaDto } from './dto/invitacion-tanda.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { JwtPayload } from '../auth/strategies/jwt.strategy';

interface RequestWithUser extends Request {
  user: JwtPayload;
}

@UseGuards(JwtAuthGuard)
@Controller('invitaciones-tanda')
export class InvitacionesTandaController {
  constructor(private readonly invitacionesTandaService: InvitacionesTandaService) {}

  @Post()
  create(@Request() req: RequestWithUser, @Body() dto: CreateInvitacionTandaDto) {
    return this.invitacionesTandaService.create(dto, req.user.sub);
  }

  @Get('tanda/:tandaId')
  findByTanda(@Param('tandaId', ParseUUIDPipe) tandaId: string) {
    return this.invitacionesTandaService.findByTanda(tandaId);
  }

  @Get('codigo/:codigo')
  findByCodigo(@Param('codigo') codigo: string) {
    return this.invitacionesTandaService.findByCodigo(codigo);
  }

  @Patch(':id/cancelar')
  cancelar(@Param('id', ParseUUIDPipe) id: string) {
    return this.invitacionesTandaService.cancelar(id);
  }
}
