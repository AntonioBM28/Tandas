import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads/',
  });

  // ─── CORS ───────────────────────────────────────────────────────────────────
  // Enabled for Flutter apps (Mobile, Wear OS, Smart TV)
  app.enableCors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // ─── Global Validation Pipe ──────────────────────────────────────────────────
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,              // Strip unknown properties
      forbidNonWhitelisted: true,   // Throw error if unknown props are sent
      transform: true,              // Auto-transform payloads to DTO instances
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // ─── Start Server ────────────────────────────────────────────────────────────
  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT') ?? 3000;

  await app.listen(port);
  console.log(`🚀 API Tandas running on http://localhost:${port}`);
}

bootstrap();
