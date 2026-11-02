import pino from 'pino';
import { LOG_REDACT_PATHS } from './logger.module';

describe('LOG_REDACT_PATHS (S11, T-11)', () => {
  it('no deja credenciales, cookies ni IP en la línea de log', () => {
    let out = '';
    const logger = pino(
      { redact: LOG_REDACT_PATHS },
      { write: (line: string) => (out += line) },
    );

    logger.info({
      req: {
        url: '/api/v1/map/buildings',
        remoteAddress: '203.0.113.7',
        headers: {
          authorization: 'Bearer secreto-jwt',
          cookie: 'sid=secreto-cookie',
          'x-forwarded-for': '198.51.100.9',
          accept: 'application/json',
        },
      },
      res: { statusCode: 200, headers: { 'set-cookie': 'sid=otra-cookie' } },
    });

    for (const secreto of [
      'secreto-jwt',
      'secreto-cookie',
      '198.51.100.9',
      '203.0.113.7',
      'otra-cookie',
    ]) {
      expect(out).not.toContain(secreto);
    }
    // Lo que no es sensible sigue visible para depurar.
    expect(out).toContain('/api/v1/map/buildings');
    expect(out).toContain('application/json');
  });
});
