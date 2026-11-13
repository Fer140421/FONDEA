import type { RequestHandler } from 'express';
import type { SupabaseIntegration } from '../integrations/supabase.js';
import { HttpError } from '../shared/http-error.js';

export function authenticate(supabase: SupabaseIntegration): RequestHandler {
  return async (request, response, next) => {
    const match = /^Bearer ([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)$/i.exec(
      request.headers.authorization ?? '',
    );
    const token = match?.[1];
    if (!token) {
      response.setHeader('WWW-Authenticate', 'Bearer');
      throw new HttpError(401, 'UNAUTHORIZED', 'Se requiere un access token válido.');
    }
    const user = await supabase.verifyToken(token);
    if (!user) {
      response.setHeader('WWW-Authenticate', 'Bearer error="invalid_token"');
      throw new HttpError(401, 'UNAUTHORIZED', 'Access token inválido o caducado.');
    }
    request.user = user;
    request.supabase = supabase.forUser(token);
    next();
  };
}
