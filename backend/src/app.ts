import express, { type ErrorRequestHandler } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import type { Config } from './config/env.js';
import { createSupabaseIntegration, type SupabaseIntegration } from './integrations/supabase.js';
import { authenticate } from './middleware/auth.js';
import { createModuleRouter } from './modules/routes.js';
import { HttpError } from './shared/http-error.js';

export function createApp(
  config: Config,
  dependencies: { supabase?: SupabaseIntegration } = {},
) {
  const app = express();
  const supabase = dependencies.supabase ?? createSupabaseIntegration(config);
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({
    origin: config.ALLOWED_ORIGINS,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type'],
  }));
  app.get('/health', (_request, response) => {
    response.json({ status: 'ok' });
  });

  const api = express.Router();
  api.use((_request, response, next) => {
    response.setHeader('Cache-Control', 'no-store');
    next();
  });
  api.use(authenticate(supabase));
  api.use(express.json({ limit: '1mb' }));
  api.get('/me', (request, response) => {
    response.json({ user: { id: request.user!.id } });
  });
  api.use(createModuleRouter());
  app.use('/api/v1', api);
  app.use((_request, _response) => {
    throw new HttpError(404, 'NOT_FOUND', 'Ruta no encontrada.');
  });
  const errorHandler: ErrorRequestHandler = (error: unknown, _request, response, _next) => {
    if (error instanceof HttpError) {
      response.status(error.status).json({ error: { code: error.code, message: error.message } });
      return;
    }
    if (typeof error === 'object' && error !== null && 'type' in error) {
      if (error.type === 'entity.parse.failed') {
        response.status(400).json({ error: { code: 'INVALID_JSON', message: 'JSON inválido.' } });
        return;
      }
      if (error.type === 'entity.too.large') {
        response.status(413).json({ error: { code: 'PAYLOAD_TOO_LARGE', message: 'Petición demasiado grande.' } });
        return;
      }
    }
    // No devolver errores del SDK, cabeceras, tokens ni trazas al cliente.
    console.error('Error interno al procesar una petición.');
    response.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Error interno.' } });
  };
  app.use(errorHandler);
  return app;
}
