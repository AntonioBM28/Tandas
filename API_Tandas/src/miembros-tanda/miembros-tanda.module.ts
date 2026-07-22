import { Module } from '@nestjs/common';
import { MiembrosTandaController } from './miembros-tanda.controller';
import { MiembrosTandaService } from './miembros-tanda.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [MiembrosTandaController],
  providers: [MiembrosTandaService],
  exports: [MiembrosTandaService],
})
export class MiembrosTandaModule {}
