import { Module } from '@nestjs/common';
import { LoggerModule as PinoLoggerModule } from 'nestjs-pino';

// S11 (T-11): no dejar en los logs credenciales ni datos personales.
export const LOG_REDACT_PATHS = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.headers["x-forwarded-for"]',
  'req.remoteAddress',
  'res.headers["set-cookie"]',
];

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
        redact: LOG_REDACT_PATHS,
      },
    }),
  ],
  exports: [PinoLoggerModule],
})
export class LoggerModule {}
