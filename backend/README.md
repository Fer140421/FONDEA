# Backend Fondea

Espacio reservado para el servicio Node.js y la integración de servidor con Supabase, a iniciar cuando se definan los límites del producto y sus especificaciones.

1. Instala Node.js LTS.
2. Copia `.env.example` a `.env` y configura secretos de desarrollo.
3. Nunca expongas `SUPABASE_SERVICE_ROLE_KEY` a Flutter, Git, logs ni clientes.

Las claves de Supabase deben acompañarse de políticas RLS; la clave de servicio omite RLS y solo debe usarse en operaciones de servidor cuidadosamente autorizadas.
