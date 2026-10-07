-- Werkbuch Aufgaben: Datenbank-Schema
-- Einmal im Supabase SQL Editor ausführen. Das Skript kann gefahrlos mehrmals laufen.

-- Tabellen: jede Zeile gehört genau einem Benutzer. "data" enthält den Inhalt als JSON,
-- "deleted" markiert gelöschte Einträge (damit andere Geräte das Löschen mitbekommen),
-- "updated_at" setzt der Server selbst und dient als Synchronisations-Zeitstempel.
create table if not exists public.areas (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  data jsonb not null default '{}'::jsonb,
  deleted boolean not null default false,
  updated_at timestamptz not null default now()
);
create table if not exists public.tasks (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  data jsonb not null default '{}'::jsonb,
  deleted boolean not null default false,
  updated_at timestamptz not null default now()
);
create table if not exists public.meetings (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  data jsonb not null default '{}'::jsonb,
  deleted boolean not null default false,
  updated_at timestamptz not null default now()
);

create index if not exists areas_user_updated on public.areas (user_id, updated_at);
create index if not exists tasks_user_updated on public.tasks (user_id, updated_at);
create index if not exists meetings_user_updated on public.meetings (user_id, updated_at);

-- Server-Zeitstempel bei jeder Änderung
create or replace function public.werkbuch_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  if tg_op = 'UPDATE' then new.user_id := old.user_id; end if; -- Besitzer kann nicht geändert werden
  return new;
end $$;

drop trigger if exists areas_touch on public.areas;
drop trigger if exists tasks_touch on public.tasks;
drop trigger if exists meetings_touch on public.meetings;
create trigger areas_touch before insert or update on public.areas for each row execute function public.werkbuch_touch();
create trigger tasks_touch before insert or update on public.tasks for each row execute function public.werkbuch_touch();
create trigger meetings_touch before insert or update on public.meetings for each row execute function public.werkbuch_touch();

-- Zugriff über die App erlauben (nötig, falls neue Tabellen nicht automatisch freigegeben werden)
grant select, insert, update, delete on public.areas, public.tasks, public.meetings to authenticated;

-- Zugriff: jeder sieht und ändert nur seine eigenen Zeilen
alter table public.areas enable row level security;
alter table public.tasks enable row level security;
alter table public.meetings enable row level security;

do $$
declare t text;
begin
  foreach t in array array['areas','tasks','meetings'] loop
    execute format('drop policy if exists "eigene Zeilen" on public.%I', t);
    execute format('create policy "eigene Zeilen" on public.%I for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;

-- Live-Aktualisierung zwischen Geräten
do $$
declare t text;
begin
  foreach t in array array['areas','tasks','meetings'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- Ablage für Fotos und PDFs: privat, jeder Benutzer nur in seinem eigenen Ordner (<user-id>/...)
insert into storage.buckets (id, name, public, file_size_limit)
values ('anhaenge', 'anhaenge', false, 26214400)
on conflict (id) do nothing;

drop policy if exists "anhaenge lesen" on storage.objects;
drop policy if exists "anhaenge schreiben" on storage.objects;
drop policy if exists "anhaenge aendern" on storage.objects;
drop policy if exists "anhaenge loeschen" on storage.objects;
create policy "anhaenge lesen" on storage.objects for select to authenticated
  using (bucket_id = 'anhaenge' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "anhaenge schreiben" on storage.objects for insert to authenticated
  with check (bucket_id = 'anhaenge' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "anhaenge aendern" on storage.objects for update to authenticated
  using (bucket_id = 'anhaenge' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "anhaenge loeschen" on storage.objects for delete to authenticated
  using (bucket_id = 'anhaenge' and (storage.foldername(name))[1] = auth.uid()::text);
