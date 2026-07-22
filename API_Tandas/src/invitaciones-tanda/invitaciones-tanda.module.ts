import { Module } from '@nestjs/common';
import { InvitacionesTandaController } from './invitaciones-tanda.controller';
import { InvitacionesTandaService } from './invitaciones-tanda.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [InvitacionesTandaController],
  providers: [InvitacionesTandaService],
  exports: [InvitacionesTandaService],
})
export class InvitacionesTandaModule {}
