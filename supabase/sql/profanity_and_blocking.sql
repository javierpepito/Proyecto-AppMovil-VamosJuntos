-- 1) Tabla de bloqueos
create table if not exists public.usuarios_bloqueados (
  id bigserial primary key,
  usuario_fk bigint not null references public.usuarios(id) on delete cascade,
  bloqueado_fk bigint not null references public.usuarios(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (usuario_fk, bloqueado_fk)
);

-- 2) Tabla de palabras prohibidas
create table if not exists public.profanity_words (
  word text primary key
);

-- 3) Log de moderación
create table if not exists public.mensajes_moderacion (
  id bigserial primary key,
  mensaje_id bigint,
  chat_fk bigint,
  usuario_fk bigint,
  contenido text,
  motivo text,
  created_at timestamptz not null default now()
);

-- 4) Función para detectar malas palabras
create or replace function public.contains_profanity(p_text text)
returns boolean
language plpgsql
as $$
declare
  w text;
begin
  for w in select word from public.profanity_words loop
    if p_text ilike '%' || w || '%' then
      return true;
    end if;
  end loop;
  return false;
end;
$$;

-- 5) Trigger AFTER INSERT en mensajes: log y borrado si hay malas palabras
create or replace function public.trg_mensajes_profanity()
returns trigger
language plpgsql
as $$
begin
  if public.contains_profanity(new.contenido) then
    insert into public.mensajes_moderacion(mensaje_id, chat_fk, usuario_fk, contenido, motivo)
    values (new.id, new.chat_id, new.usuario_id, new.contenido, 'profanity');
    delete from public.mensajes where id = new.id;
    return null;
  end if;
  return new;
end;
$$;

drop trigger if exists tr_mensajes_profanity on public.mensajes;
create trigger tr_mensajes_profanity
after insert on public.mensajes
for each row execute function public.trg_mensajes_profanity();

-- 6) Habilitar RLS
alter table public.mensajes enable row level security;
alter table public.chat_participantes enable row level security;
alter table public.usuarios enable row level security;
alter table public.usuarios_bloqueados enable row level security;

-- 7) Helper: id de usuarios por email del JWT
create or replace function public.current_usuario_id()
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select id from public.usuarios where email = (auth.jwt() ->> 'email');
$$;

-- 8) Policies
-- usuarios
drop policy if exists p_usuarios_self_select on public.usuarios;
create policy p_usuarios_self_select
on public.usuarios for select
using (email = (auth.jwt() ->> 'email'));

drop policy if exists p_usuarios_self_update on public.usuarios;
create policy p_usuarios_self_update
on public.usuarios for update
using (email = (auth.jwt() ->> 'email'));

-- chat_participantes
drop policy if exists p_chat_participantes_select on public.chat_participantes;
create policy p_chat_participantes_select
on public.chat_participantes for select
using (usuario_fk = public.current_usuario_id());

-- mensajes
drop policy if exists p_mensajes_select on public.mensajes;
create policy p_mensajes_select
on public.mensajes for select
using (
  exists (
    select 1 from public.chat_participantes cp
    where cp.chat_id = mensajes.chat_id
      and cp.usuario_fk = public.current_usuario_id()
  )
  and not exists (
    select 1 from public.usuarios_bloqueados b
    where b.usuario_fk = public.current_usuario_id()
      and b.bloqueado_fk = mensajes.usuario_id
  )
);

drop policy if exists p_mensajes_insert on public.mensajes;
create policy p_mensajes_insert
on public.mensajes for insert
with check (
  exists (
    select 1 from public.chat_participantes cp
    where cp.chat_id = mensajes.chat_id
      and cp.usuario_fk = public.current_usuario_id()
  )
);

-- usuarios_bloqueados
drop policy if exists p_bloq_select on public.usuarios_bloqueados;
create policy p_bloq_select
on public.usuarios_bloqueados for select
using (usuario_fk = public.current_usuario_id());

drop policy if exists p_bloq_insert on public.usuarios_bloqueados;
create policy p_bloq_insert
on public.usuarios_bloqueados for insert
with check (usuario_fk = public.current_usuario_id());

drop policy if exists p_bloq_delete on public.usuarios_bloqueados;
create policy p_bloq_delete
on public.usuarios_bloqueados for delete
using (usuario_fk = public.current_usuario_id());
