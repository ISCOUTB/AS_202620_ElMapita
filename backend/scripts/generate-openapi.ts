import { writeFileSync } from 'fs';
import { resolve } from 'path';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from '../src/app.module';

/**
 * Genera el documento OpenAPI real desde los decoradores de NestJS,
 * replicando el bootstrap de src/main.ts (mismo setGlobalPrefix), para
 * poder compararlo contra docs/api/openapi.v1.yaml (ver check-openapi-drift.ts).
 * No hace `listen()`: solo construye el documento y sale.
 */
async function main() {
  const app = await NestFactory.create(AppModule, { logger: false });
  app.setGlobalPrefix('api');

  const config = new DocumentBuilder()
    .setTitle('El Mapita UTB API')
    .setDescription('API para la aplicación de mapa 3D interactivo del campus UTB')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  const outPath = resolve(__dirname, '../.openapi-generated.json');
  writeFileSync(outPath, JSON.stringify(document, null, 2));
  console.log(`OpenAPI generado en tiempo de ejecución escrito en ${outPath}`);

  await app.close();
}

main().catch((err) => {
  console.error('Error generando OpenAPI desde NestJS:', err);
  process.exit(1);
});
