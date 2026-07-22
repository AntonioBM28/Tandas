import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { join } from 'path';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsuariosModule } from './usuarios/usuarios.module';
import { TandasModule } from './tandas/tandas.module';
import { MiembrosTandaModule } from './miembros-tanda/miembros-tanda.module';
import { InvitacionesTandaModule } from './invitaciones-tanda/invitaciones-tanda.module';
import { CiclosPagoModule } from './ciclos-pago/ciclos-pago.module';
import { PagosModule } from './pagos/pagos.module';
import { NotificacionesModule } from './notificaciones/notificaciones.module';

@Module({
  imports: [
    // ─── Config (Global) ──────────────────────────────────────────────────────
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    // ─── Core Module ──────────────────────────────────────────────────────────
    PrismaModule,

    // ─── Feature Modules ──────────────────────────────────────────────────────
    AuthModule,
    UsuariosModule,
    TandasModule,
    MiembrosTandaModule,
    InvitacionesTandaModule,
    CiclosPagoModule,
    PagosModule,
    NotificacionesModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
