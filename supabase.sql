-- =============================================================
-- Painel Yale Barbosa · funil, clientes, jornada e agenda
-- =============================================================

create extension if not exists pgcrypto;

-- Configurações (uma linha por usuária) ------------------------
create table if not exists public.configuracoes (
  owner_id        uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  google_agenda   text,     -- e-mail da Agenda do Google para mostrar no painel
  whatsapp        text,     -- WhatsApp de atendimento (só números)
  updated_at      timestamptz not null default now()
);

-- Clientes -----------------------------------------------------
create table if not exists public.clientes (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  token           uuid not null unique default gen_random_uuid(),
  nome            text not null,
  email           text,
  whatsapp        text,
  profissao       text,
  inicio          date,
  valor_mensal    numeric(12,2),
  situacao        text not null default 'ativo' check (situacao in ('ativo','pausado','encerrado')),
  observacoes     text,
  como_iniciamos  text,
  onde_estamos    text,
  para_onde_vamos text,
  ativo           boolean not null default true,  -- link da jornada ligado/desligado
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Encontros da jornada -----------------------------------------
create table if not exists public.reunioes (
  id          uuid primary key default gen_random_uuid(),
  cliente_id  uuid not null references public.clientes(id) on delete cascade,
  owner_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  ordem       int  not null,
  data        date,
  hora        text,
  tema        text,
  realizada   boolean not null default false,
  resumo      text,
  combinados  text,
  created_at  timestamptz not null default now()
);
create index if not exists reunioes_cliente_ordem on public.reunioes (cliente_id, ordem);

-- Funil (CRM) ---------------------------------------------------
create table if not exists public.leads (
  id                  uuid primary key default gen_random_uuid(),
  owner_id            uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome                text not null,
  whatsapp            text,
  email               text,
  origem              text,
  profissao           text,
  renda_faixa         text,
  momento             text,
  quando_comecar      text,
  motivo              text,     -- momento de vida, dor e objetivo
  etapa               text not null default 'novo'
                      check (etapa in ('novo','contato','diagnostico','proposta','followup','fechado','perdido')),
  etapa_desde         timestamptz not null default now(),
  diagnostico_em      timestamptz,
  proximo_passo       text,
  proximo_passo_data  date,
  valor_proposta      numeric(12,2),
  motivo_perda        text,
  cliente_id          uuid references public.clientes(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index if not exists leads_etapa on public.leads (owner_id, etapa);

create table if not exists public.atividades (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  lead_id    uuid not null references public.leads(id) on delete cascade,
  tipo       text not null default 'nota',
  texto      text not null,
  criado_em  timestamptz not null default now()
);
create index if not exists atividades_lead on public.atividades (lead_id, criado_em desc);

-- Datas de atualização -----------------------------------------
create or replace function public.tocar_updated_at() returns trigger
language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  if tg_table_name = 'leads' and new.etapa is distinct from old.etapa then
    new.etapa_desde = now();
  end if;
  return new;
end $$;

drop trigger if exists clientes_updated on public.clientes;
create trigger clientes_updated before update on public.clientes for each row execute function public.tocar_updated_at();
drop trigger if exists leads_updated on public.leads;
create trigger leads_updated before update on public.leads for each row execute function public.tocar_updated_at();

create or replace function public.tocar_cliente_pela_reuniao() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.clientes set updated_at = now() where id = coalesce(new.cliente_id, old.cliente_id);
  return null;
end $$;
revoke all on function public.tocar_cliente_pela_reuniao() from public, anon, authenticated;

drop trigger if exists reunioes_tocam_cliente on public.reunioes;
create trigger reunioes_tocam_cliente after insert or update or delete on public.reunioes
for each row execute function public.tocar_cliente_pela_reuniao();

-- Segurança: só a dona lê e altera -----------------------------
alter table public.configuracoes enable row level security;
alter table public.clientes      enable row level security;
alter table public.reunioes      enable row level security;
alter table public.leads         enable row level security;
alter table public.atividades    enable row level security;

drop policy if exists "dona" on public.configuracoes;
create policy "dona" on public.configuracoes for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
drop policy if exists "dona" on public.clientes;
create policy "dona" on public.clientes for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
drop policy if exists "dona" on public.leads;
create policy "dona" on public.leads for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
drop policy if exists "dona" on public.reunioes;
create policy "dona" on public.reunioes for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and exists (select 1 from public.clientes c where c.id = cliente_id and c.owner_id = (select auth.uid())));
drop policy if exists "dona" on public.atividades;
create policy "dona" on public.atividades for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) and exists (select 1 from public.leads l where l.id = lead_id and l.owner_id = (select auth.uid())));

-- Página do cliente: leitura só pelo código do link -------------
create or replace function public.jornada_do_cliente(p_token uuid)
returns json language sql stable security definer set search_path = public as $$
  select json_build_object(
    'nome', c.nome, 'inicio', c.inicio,
    'como_iniciamos', c.como_iniciamos, 'onde_estamos', c.onde_estamos, 'para_onde_vamos', c.para_onde_vamos,
    'atualizado_em', c.updated_at,
    'whatsapp', (select g.whatsapp from public.configuracoes g where g.owner_id = c.owner_id),
    'reunioes', coalesce((
      select json_agg(json_build_object('ordem', r.ordem, 'data', r.data, 'hora', r.hora, 'tema', r.tema,
        'realizada', r.realizada, 'resumo', r.resumo, 'combinados', r.combinados) order by r.ordem)
      from public.reunioes r where r.cliente_id = c.id), '[]'::json)
  )
  from public.clientes c where c.token = p_token and c.ativo;
$$;
revoke all on function public.jornada_do_cliente(uuid) from public;
grant execute on function public.jornada_do_cliente(uuid) to anon, authenticated;

-- Formulário de diagnóstico -> novo lead no funil ---------------
create or replace function public.novo_lead(
  p_nome text, p_whatsapp text default null, p_email text default null,
  p_origem text default null, p_profissao text default null, p_renda text default null,
  p_momento text default null, p_quando text default null, p_mensagem text default null
) returns boolean
language plpgsql security definer set search_path = public as $$
declare v_owner uuid;
begin
  if coalesce(trim(p_nome), '') = '' then return false; end if;
  select id into v_owner from auth.users order by created_at limit 1;
  if v_owner is null then return false; end if;
  -- trava simples contra envio em massa
  if (select count(*) from public.leads where owner_id = v_owner and created_at > now() - interval '10 minutes') > 30 then
    return false;
  end if;
  insert into public.leads (owner_id, nome, whatsapp, email, origem, profissao, renda_faixa, momento, quando_comecar, motivo)
  values (v_owner, left(trim(p_nome), 120), left(p_whatsapp, 40), left(p_email, 160), left(coalesce(p_origem, 'Formulário de diagnóstico'), 80),
          left(p_profissao, 80), left(p_renda, 60), left(p_momento, 120), left(p_quando, 60), left(p_mensagem, 2000));
  return true;
end $$;
revoke all on function public.novo_lead(text,text,text,text,text,text,text,text,text) from public;
grant execute on function public.novo_lead(text,text,text,text,text,text,text,text,text) to anon, authenticated;
