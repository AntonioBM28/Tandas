import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  root(): { message: string; version: string } {
    return { message: '🚀 API Tandas funcionando correctamente', version: '1.0.0' };
  }

  @Get('health')
  healthCheck(): { status: string } {
    return { status: 'ok' };
  }
}
