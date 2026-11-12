-- T03: recursos técnicos de verificación, sin tablas de negocio.
-- Ejecutar completo en el SQL Editor de Supabase. Puede volver a ejecutarse.
begin;

create table if not exists public.backend_connection_checks (
  id integer primary key check (id = 1),
  message text not null
);

alter table public.backend_connection_checks enable row level security;
revoke all on table public.backend_connection_checks from anon, authenticated;
grant select on table public.backend_connection_checks to authenticated;

insert into public.backend_connection_checks (id, message)
values (1, 'fondea-backend-ready')
on conflict (id) do update set message = excluded.message;

drop policy if exists backend_checks_read on public.backend_connection_checks;
create policy backend_checks_read on public.backend_connection_checks
  for select to authenticated using (true);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'fondea-backend-checks', 'fondea-backend-checks', false,
  1024, array['text/plain']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- El primer segmento de la ruta debe ser el UUID del usuario autenticado.
drop policy if exists backend_checks_upload_own on storage.objects;
create policy backend_checks_upload_own on storage.objects
  for insert to authenticated with check (
    bucket_id = 'fondea-backend-checks'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists backend_checks_read_own on storage.objects;
create policy backend_checks_read_own on storage.objects
  for select to authenticated using (
    bucket_id = 'fondea-backend-checks'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists backend_checks_delete_own on storage.objects;
create policy backend_checks_delete_own on storage.objects
  for delete to authenticated using (
    bucket_id = 'fondea-backend-checks'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

commit;
