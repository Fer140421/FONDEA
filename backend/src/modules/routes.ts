import { Router } from 'express';
import { createRegistroRouter } from './registro/routes.js';
import { createSolicitudesRouter } from './solicitudes/routes.js';
import { createAportesRouter } from './aportes/routes.js';
import { createEtapasRouter } from './etapas/routes.js';
import { createCuotasRouter } from './cuotas/routes.js';

export function createModuleRouter() {
  const router = Router();
  router.use('/registro', createRegistroRouter());
  router.use('/solicitudes', createSolicitudesRouter());
  router.use('/aportes', createAportesRouter());
  router.use('/etapas', createEtapasRouter());
  router.use('/cuotas', createCuotasRouter());
  return router;
}
