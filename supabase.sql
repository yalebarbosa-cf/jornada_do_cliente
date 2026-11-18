-- =============================================================
-- Jornada do Cliente · Yale Barbosa Planejadora Financeira
-- Cole este arquivo inteiro no Supabase: SQL Editor > New query > Run
-- =============================================================

create extension if not exists pgcrypto;

-- Clientes -----------------------------------------------------
create table if not exists public.clientes (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  token           uuid not null unique default gen_random_uuid(),  -- código secreto do link do cliente
  nome            text not null,
  email           text,
  whatsapp        text,
  inicio          date,
  observacoes     text,      -- anotações internas, nunca aparecem para o cliente
  como_iniciamos  text,
  onde_estamos    text,
  para_onde_vamos text,
  ativo           boolean not null default true,  -- desligar = o link para de funcionar
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Encontros (as paradas do caminho) ----------------------------
create table if not exists public.reunioes (
  id          uuid primary key default gen_random_uuid(),
  cliente_id  uuid not null references public.clientes(id) on delete cascade,
  owner_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ordem       int  not null,
  data        date,
  tema        text,
  realizada   boolean not null default false,
  resumo      text,   -- o que foi decidido
  combinados  text,   -- o que foi combinado até o próximo encontro (um por linha)
  created_at  timestamptz not null default now()
);
create index if not exists reunioes_cliente_ordem on public.reunioes (cliente_id, ordem);

-- Data de última atualização -----------------------------------
create or replace function public.tocar_updated_at() returns trigger
language plpgsql as $$ begin new.updated_at = now(); return new; end $$;

drop trigger if exists clientes_updated on public.clientes;
create trigger clientes_updated before update on public.clientes
for each row execute function public.tocar_updated_at();

create or replace function public.tocar_cliente_pela_reuniao() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.clientes set updated_at = now()
  where id = coalesce(new.cliente_id, old.cliente_id);
  return null;
end $$;

drop trigger if exists reunioes_tocam_cliente on public.reunioes;
create trigger reunioes_tocam_cliente after insert or update or delete on public.reunioes
for each row execute function public.tocar_cliente_pela_reuniao();

-- Segurança: só você (logada no painel) lê e altera ------------
alter table public.clientes enable row level security;
alter table public.reunioes enable row level security;

drop policy if exists "dona gerencia clientes" on public.clientes;
create policy "dona gerencia clientes" on public.clientes
  for all to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "dona gerencia reunioes" on public.reunioes;
create policy "dona gerencia reunioes" on public.reunioes
  for all to authenticated
  using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and exists (select 1 from public.clientes c where c.id = cliente_id and c.owner_id = auth.uid())
  );

-- Leitura do cliente: só pelo código secreto do link -----------
-- Devolve apenas o que aparece na página dele (sem e-mail, WhatsApp ou observações).
create or replace function public.jornada_do_cliente(p_token uuid)
returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'nome',            c.nome,
    'inicio',          c.inicio,
    'como_iniciamos',  c.como_iniciamos,
    'onde_estamos',    c.onde_estamos,
    'para_onde_vamos', c.para_onde_vamos,
    'atualizado_em',   c.updated_at,
    'reunioes', coalesce((
      select json_agg(json_build_object(
        'ordem', r.ordem, 'data', r.data, 'tema', r.tema,
        'realizada', r.realizada, 'resumo', r.resumo, 'combinados', r.combinados
      ) order by r.ordem)
      from public.reunioes r where r.cliente_id = c.id
    ), '[]'::json)
  )
  from public.clientes c
  where c.token = p_token and c.ativo;
$$;

revoke all on function public.jornada_do_cliente(uuid) from public;
grant execute on function public.jornada_do_cliente(uuid) to anon, authenticated;
