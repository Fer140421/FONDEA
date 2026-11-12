import { z } from 'zod';

const httpUrl = z.url().refine((value) => {
  if (!URL.canParse(value)) return false;
  const url = new URL(value);
  return ['http:', 'https:'].includes(url.protocol) && !url.username && !url.password;
});

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  SUPABASE_URL: httpUrl.transform((value) => value.replace(/\/$/, '')),
  SUPABASE_PUBLISHABLE_KEY: z.string().startsWith('sb_publishable_').refine(
    (value) => value.length > 20 && !value.includes('replace'),
  ),
  SUPABASE_STORAGE_BUCKET: z.literal('fondea-backend-checks').default('fondea-backend-checks'),
  ALLOWED_ORIGINS: z.string().default('').transform(
    (value) => value.split(',').map((origin) => origin.trim()).filter(Boolean),
  ).pipe(z.array(httpUrl.refine((value) => URL.canParse(value) && new URL(value).origin === value))),
  STELLAR_NETWORK: z.literal('testnet').default('testnet'),
  STELLAR_HORIZON_URL: z.literal('https://horizon-testnet.stellar.org').default(
    'https://horizon-testnet.stellar.org',
  ),
});

export type Config = z.infer<typeof schema>;

export function loadConfig(environment: NodeJS.ProcessEnv = process.env): Config {
  const result = schema.safeParse(environment);
  if (!result.success) {
    const fields = [...new Set(result.error.issues.map((issue) => issue.path.join('.')))];
    // No incluir los valores introducidos (pueden contener credenciales).
    throw new Error(`Configuración inválida. Revisa: ${fields.join(', ')}.`);
  }
  return result.data;
}
