import { Module } from '@nestjs/common';
import { CiclosPagoController } from './ciclos-pago.controller';
import { CiclosPagoService } from './ciclos-pago.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [CiclosPagoController],
  providers: [CiclosPagoService],
  exports: [CiclosPagoService],
})
export class CiclosPagoModule {}
