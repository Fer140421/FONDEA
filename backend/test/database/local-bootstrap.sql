-- Solo la instancia de pruebas creada por compose.database.yml.
alter role supabase_storage_admin login password 'postgres';
alter role authenticator login password 'postgres';
alter role supabase_auth_admin login password 'postgres';
