-- =====================================================================
-- Tareas: esquema de Supabase (proyecto app-tareas)
--
-- Pegar entero en el SQL Editor y ejecutar. Se puede volver a correr sin
-- romper nada: todo usa "if not exists", "or replace" o "drop ... if exists".
--
-- Seguridad: cada fila tiene dueño (user_id) y las reglas (RLS) solo dejan
-- leer y escribir al usuario logueado que es su dueño. Sin sesión (rol anon)
-- no se ve nada, aunque la clave publishable esté a la vista en el HTML.
-- =====================================================================

-- Las funciones de los triggers van en un esquema propio, fuera de "public",
-- para que la API de Supabase no las exponga.
create schema if not exists privado;


-- ---------------------------------------------------------------------
-- Tablas
-- ---------------------------------------------------------------------

create table if not exists public.tareas (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  titulo         text not null,
  notas          text,
  lista          text not null check (lista in ('inbox', 'mias', 'delegadas', 'algun_dia')),
  fecha          date,
  hora           time,
  recordatorio   int,                -- minutos antes: 0, 15, 60 o 1440
  prioridad      text not null default 'normal' check (prioridad in ('alta', 'normal', 'baja')),
  delegado_a     text,
  completada     boolean not null default false,
  completada_el  timestamptz,
  recurrencia    text check (recurrencia in ('diaria', 'diasHabiles', 'semanal', 'mensual')),
  notificada     boolean not null default false,
  origen         text not null default 'app',   -- 'app' o 'claude'
  creada         timestamptz not null default now(),
  actualizada    timestamptz not null default now()
);

-- Valores sueltos de la app: "tres_para_hoy" (por fecha), "ultimo_repaso" e "inicializado".
create table if not exists public.config (
  user_id      uuid not null references auth.users (id) on delete cascade,
  clave        text not null,
  valor        jsonb,
  actualizada  timestamptz not null default now(),
  primary key (user_id, clave)
);

-- La consulta típica: lo pendiente de una lista, por fecha
create index if not exists tareas_lista_completada_fecha
  on public.tareas (user_id, lista, completada, fecha);


-- ---------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------

-- Completa el dueño cuando la fila llega sin user_id. Pasa con lo que carga
-- Claude por SQL, donde no hay sesión: se usa el primer usuario creado, que
-- en esta app es el único.
create or replace function privado.completar_dueno()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.user_id is null then
    new.user_id := coalesce(auth.uid(), (select id from auth.users order by created_at limit 1));
  end if;
  return new;
end;
$$;

-- Actualiza "actualizada" en cada cambio
create or replace function privado.tocar_actualizada()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.actualizada := now();
  return new;
end;
$$;

revoke all on function privado.completar_dueno() from public, anon, authenticated;
revoke all on function privado.tocar_actualizada() from public, anon, authenticated;

drop trigger if exists tareas_dueno on public.tareas;
create trigger tareas_dueno before insert on public.tareas
  for each row execute function privado.completar_dueno();

drop trigger if exists tareas_actualizada on public.tareas;
create trigger tareas_actualizada before update on public.tareas
  for each row execute function privado.tocar_actualizada();

drop trigger if exists config_dueno on public.config;
create trigger config_dueno before insert on public.config
  for each row execute function privado.completar_dueno();

drop trigger if exists config_actualizada on public.config;
create trigger config_actualizada before update on public.config
  for each row execute function privado.tocar_actualizada();


-- ---------------------------------------------------------------------
-- Seguridad (RLS)
-- ---------------------------------------------------------------------

alter table public.tareas enable row level security;
alter table public.config enable row level security;

drop policy if exists "solo el dueño" on public.tareas;
create policy "solo el dueño" on public.tareas
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "solo el dueño" on public.config;
create policy "solo el dueño" on public.config
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Sin sesión no hay acceso de ningún tipo
revoke all on public.tareas, public.config from anon;
grant select, insert, update, delete on public.tareas, public.config to authenticated;


-- ---------------------------------------------------------------------
-- Tiempo real: sin esto la app no se entera de los cambios de otro
-- dispositivo ni de lo que cargue Claude, y no da ningún error.
-- ---------------------------------------------------------------------

do $$
begin
  alter publication supabase_realtime add table public.tareas;
exception when duplicate_object then null;   -- ya estaba agregada
end $$;

do $$
begin
  alter publication supabase_realtime add table public.config;
exception when duplicate_object then null;
end $$;


-- =====================================================================
-- Cómo carga Claude una tarea (por el MCP de Supabase o el SQL Editor).
-- user_id se completa solo; "lista" usa los nombres de la base:
-- inbox, mias, delegadas, algun_dia.
--
--   insert into public.tareas (titulo, lista, fecha, hora, recordatorio, prioridad, origen)
--   values ('Llamar al proveedor', 'mias', '2026-09-25', '09:00', 0, 'alta', 'claude');
--
-- Y cómo lee lo pendiente:
--
--   select titulo, lista, fecha, hora, prioridad, delegado_a
--   from public.tareas
--   where not completada
--   order by fecha nulls last, hora nulls last;
-- =====================================================================
