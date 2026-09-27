import { Module } from '@nestjs/common';
import { LoggerModule as PinoLoggerModule } from 'nestjs-pino';

@Module({
  imports: [
    PinoLoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL || 'info',
        // JSON crudo en producción (Render lo captura de stdout tal cual);
        // pretty-print solo en desarrollo local.
        transport:
          process.env.NODE_ENV === 'production'
            ? undefined
            : { target: 'pino-pretty', options: { singleLine: true } },
        autoLogging: {
          ignore: (req) => req.url === '/health' || req.url === '/metrics',
        },
        redact: ['req.headers.authorization'],
      },
    }),
  ],
  exports: [PinoLoggerModule],
})
export class LoggerModule {}
