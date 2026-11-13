import { createApp } from './app.js';
import { loadConfig } from './config/env.js';
import { createStellarIntegration } from './integrations/stellar.js';

try {
  const config = loadConfig();
  const app = createApp(config);
  app.locals.stellar = createStellarIntegration(config);
  const server = app.listen(config.PORT, () => {
    console.log(`Fondea backend escuchando en el puerto ${config.PORT} (${config.NODE_ENV}).`);
  });
  server.on('error', () => {
    console.error('No se pudo iniciar el servidor. Revisa el puerto y los permisos.');
    process.exitCode = 1;
  });
  for (const signal of ['SIGINT', 'SIGTERM'] as const) {
    process.once(signal, () => {
      server.close(() => { process.exitCode = 0; });
      setTimeout(() => process.exit(1), 10_000).unref();
    });
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : 'No se pudo iniciar el servidor.');
  process.exitCode = 1;
}
