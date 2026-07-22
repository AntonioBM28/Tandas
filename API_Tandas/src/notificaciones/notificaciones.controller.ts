import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
  Query,
  ParseUUIDPipe,
} from '@nestjs/common';
import { NotificacionesService } from './notificaciones.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { JwtPayload } from '../auth/strategies/jwt.strategy';

interface RequestWithUser extends Request {
  user: JwtPayload;
}

@UseGuards(JwtAuthGuard)
@Controller('notificaciones')
export class NotificacionesController {
  constructor(private readonly notificacionesService: NotificacionesService) {}

  /**
   * GET /notificaciones
   * Returns notifications for the authenticated user.
   * Query param: ?soloNoLeidas=true
   */
  @Get()
  findMias(
    @Request() req: RequestWithUser,
    @Query('soloNoLeidas') soloNoLeidas?: string,
  ) {
    return this.notificacionesService.findByUsuario(
      req.user.sub,
      soloNoLeidas === 'true',
    );
  }

  /**
   * PATCH /notificaciones/:id/leer
   * Marks one notification as read.
   */
  @Patch(':id/leer')
  marcarLeida(
    @Param('id', ParseUUIDPipe) id: string,
    @Request() req: RequestWithUser,
  ) {
    return this.notificacionesService.marcarLeida(id, req.user.sub);
  }

  /**
   * PATCH /notificaciones/leer-todas
   * Marks all notifications as read for the authenticated user.
   */
  @Patch('leer-todas')
  marcarTodasLeidas(@Request() req: RequestWithUser) {
    return this.notificacionesService.marcarTodasLeidas(req.user.sub);
  }
}
