import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  app.enableCors();

  // Static files (admin dashboard)
  app.useStaticAssets(join(__dirname, '..', 'public'));

  // Body size limit for image uploads (5MB)
  app.use(require('express').json({ limit: '5mb' }));

  const config = new DocumentBuilder()
    .setTitle('DailyMemory API')
    .setDescription('AI memory analysis, embedding, and semantic search')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`DailyMemory API running on port ${port}`);
}
bootstrap();
