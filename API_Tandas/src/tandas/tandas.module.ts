import { Module } from '@nestjs/common';
import { TandasController } from './tandas.controller';
import { TandasService } from './tandas.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [TandasController],
  providers: [TandasService],
  exports: [TandasService],
})
export class TandasModule {}
