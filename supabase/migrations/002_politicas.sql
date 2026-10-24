-- =====================================================================
-- 002_politicas.sql
-- Segurança do Clinix: perfil, funções de atendimento, auditoria,
-- políticas de RLS e regra de gerente único.
-- Rode depois do 001_tabelas.sql. Pode ser rodado de novo sem erro.
-- Alterações de agendamento passam só por funções security definer.
-- =====================================================================

-- 1. Perfil do usuário, lido do app_metadata (só o servidor altera)
create or replace function public.perfil_atual() returns text
language sql stable as $$
  select case
    when auth.jwt() -> 'app_metadata' ->> 'perfil'
         in ('operador', 'administrativo', 'profissional', 'gerente')
      then auth.jwt() -> 'app_metadata' ->> 'perfil'
    else 'nenhum'
  end;
$$;

-- 2. Auditoria: registra alterações, sem acesso pelo app
create table if not exists public.auditoria (
  id bigint generated always as identity primary key,
  tabela text not null,
  operacao text not null,
  acao text,
  registro_id uuid,
  dados_antes jsonb,
  dados_depois jsonb,
  usuario_id uuid default auth.uid(),
  criado_em timestamptz not null default now()
);

alter table public.auditoria enable row level security;
revoke all on public.auditoria from anon, authenticated;

create or replace function public.registrar_auditoria()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.auditoria (tabela, operacao, acao, registro_id, dados_antes, dados_depois)
  values (
    tg_table_name,
    tg_op,
    coalesce(nullif(current_setting('app.acao', true), ''), tg_op),
    coalesce(new.id, old.id),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end
  );
  return coalesce(new, old);
end;
$$;

-- Pacientes: guarda só os campos alterados, sem os valores (LGPD)
create or replace function public.registrar_auditoria_pacientes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_campos text[];
begin
  if tg_op = 'UPDATE' then
    select array_agg(n.key order by n.key) into v_campos
    from jsonb_each(to_jsonb(new)) as n
    join jsonb_each(to_jsonb(old)) as o on o.key = n.key
    where n.value is distinct from o.value;
  end if;

  insert into public.auditoria (tabela, operacao, acao, registro_id, dados_antes, dados_depois)
  values (
    'pacientes',
    tg_op,
    coalesce(nullif(current_setting('app.acao', true), ''), tg_op),
    coalesce(new.id, old.id),
    null,
    case when tg_op = 'UPDATE'
      then jsonb_build_object('campos_alterados', coalesce(v_campos, array[]::text[]))
    end
  );
  return coalesce(new, old);
end;
$$;

drop trigger if exists auditar_agendamentos on public.agendamentos;
create trigger auditar_agendamentos
after insert or update or delete on public.agendamentos
for each row execute function public.registrar_auditoria();

drop trigger if exists auditar_funcionarios on public.funcionarios;
create trigger auditar_funcionarios
after insert or update or delete on public.funcionarios
for each row execute function public.registrar_auditoria();

drop trigger if exists auditar_pacientes on public.pacientes;
create trigger auditar_pacientes
after insert or update or delete on public.pacientes
for each row execute function public.registrar_auditoria_pacientes();

-- 3. Funções de atendimento (alteram agendamentos; o app não faz update direto)

-- Auxiliar: confere se o perfil pode agir e, para o profissional, se o atendimento é dele
create or replace function public.verificar_acesso_atendimento(p_agendamento_id uuid)
returns public.agendamentos
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_perfil text := public.perfil_atual();
  v_funcionario_id uuid;
  v_ag public.agendamentos%rowtype;
begin
  if v_perfil not in ('profissional', 'gerente') then
    raise exception 'Seu perfil não pode alterar atendimentos' using errcode = '42501';
  end if;

  select * into v_ag from public.agendamentos where id = p_agendamento_id;
  if not found then
    raise exception 'Agendamento não encontrado';
  end if;

  if v_perfil = 'profissional' then
    select id into v_funcionario_id from public.funcionarios where user_id = auth.uid();
    if v_funcionario_id is null or v_ag.profissional_id <> v_funcionario_id then
      raise exception 'Este atendimento não é seu' using errcode = '42501';
    end if;
  end if;

  return v_ag;
end;
$$;

create or replace function public.registrar_chegada(p_agendamento_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.perfil_atual() not in ('operador', 'gerente') then
    raise exception 'Seu perfil não pode registrar chegada' using errcode = '42501';
  end if;

  perform set_config('app.acao', 'registrar_chegada', true);

  update public.agendamentos
  set chegada_em = now()
  where id = p_agendamento_id and status = 'agendado';

  if not found then
    raise exception 'Só é possível registrar chegada de um agendamento marcado';
  end if;
end;
$$;

create or replace function public.iniciar_atendimento(p_agendamento_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ag public.agendamentos%rowtype;
begin
  v_ag := public.verificar_acesso_atendimento(p_agendamento_id);

  if exists (
    select 1 from public.agendamentos
    where profissional_id = v_ag.profissional_id and status = 'em_atendimento'
  ) then
    raise exception 'Este profissional já tem um atendimento em andamento';
  end if;

  perform set_config('app.acao', 'iniciar_atendimento', true);

  update public.agendamentos
  set iniciado_em = now()
  where id = p_agendamento_id and status = 'aguardando';

  if not found then
    raise exception 'Só é possível iniciar um atendimento que está aguardando';
  end if;
end;
$$;

create or replace function public.encerrar_atendimento(
  p_agendamento_id uuid,
  p_anotacoes text default ''
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.verificar_acesso_atendimento(p_agendamento_id);

  perform set_config('app.acao', 'encerrar_atendimento', true);

  update public.agendamentos
  set finalizado_em = now(),
      observacoes_administrativas = coalesce(nullif(trim(p_anotacoes), ''), observacoes_administrativas)
  where id = p_agendamento_id and status = 'em_atendimento';

  if not found then
    raise exception 'Só é possível encerrar um atendimento em andamento';
  end if;
end;
$$;

create or replace function public.cancelar_agendamento(p_agendamento_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.perfil_atual() not in ('operador', 'gerente') then
    raise exception 'Seu perfil não pode cancelar agendamentos' using errcode = '42501';
  end if;

  perform set_config('app.acao', 'cancelar_agendamento', true);

  update public.agendamentos
  set status = 'cancelado'
  where id = p_agendamento_id and status in ('agendado', 'aguardando');

  if not found then
    raise exception 'Só é possível cancelar um agendamento que ainda não começou';
  end if;
end;
$$;

-- Grants: o auxiliar não é chamado pelo app; as funções públicas só para logados
revoke all on function public.verificar_acesso_atendimento(uuid) from public, anon, authenticated;

revoke all on function public.registrar_chegada(uuid) from public, anon;
revoke all on function public.iniciar_atendimento(uuid) from public, anon;
revoke all on function public.encerrar_atendimento(uuid, text) from public, anon;
revoke all on function public.cancelar_agendamento(uuid) from public, anon;

grant execute on function public.registrar_chegada(uuid) to authenticated;
grant execute on function public.iniciar_atendimento(uuid) to authenticated;
grant execute on function public.encerrar_atendimento(uuid, text) to authenticated;
grant execute on function public.cancelar_agendamento(uuid) to authenticated;

-- 4. Políticas de RLS (leitura por perfil; escrita só onde a matriz permite)

-- Funcionários
drop policy if exists "funcionarios leem" on public.funcionarios;
create policy "funcionarios leem"
on public.funcionarios for select to authenticated
using ((select public.perfil_atual()) <> 'nenhum');

drop policy if exists "gerente cadastra funcionarios" on public.funcionarios;
create policy "gerente cadastra funcionarios"
on public.funcionarios for insert to authenticated
with check ((select public.perfil_atual()) = 'gerente');

drop policy if exists "gerente edita funcionarios" on public.funcionarios;
create policy "gerente edita funcionarios"
on public.funcionarios for update to authenticated
using ((select public.perfil_atual()) = 'gerente')
with check ((select public.perfil_atual()) = 'gerente');

-- Pacientes
drop policy if exists "pacientes leem" on public.pacientes;
create policy "pacientes leem"
on public.pacientes for select to authenticated
using (
  (select public.perfil_atual()) in ('operador', 'administrativo', 'gerente')
  or (
    (select public.perfil_atual()) = 'profissional'
    and exists (
      select 1
      from public.agendamentos a
      join public.funcionarios f on f.id = a.profissional_id
      where a.paciente_id = pacientes.id
        and f.user_id = (select auth.uid())
    )
  )
);

drop policy if exists "recepcao e gerente cadastram pacientes" on public.pacientes;
create policy "recepcao e gerente cadastram pacientes"
on public.pacientes for insert to authenticated
with check ((select public.perfil_atual()) in ('operador', 'gerente'));

drop policy if exists "recepcao e gerente corrigem pacientes" on public.pacientes;
create policy "recepcao e gerente corrigem pacientes"
on public.pacientes for update to authenticated
using ((select public.perfil_atual()) in ('operador', 'gerente'))
with check ((select public.perfil_atual()) in ('operador', 'gerente'));

-- Agendamentos (sem update nem delete: alterações passam pelas funções)
drop policy if exists "agendamentos leem" on public.agendamentos;
create policy "agendamentos leem"
on public.agendamentos for select to authenticated
using (
  (select public.perfil_atual()) in ('operador', 'administrativo', 'gerente')
  or (
    (select public.perfil_atual()) = 'profissional'
    and profissional_id in (
      select f.id from public.funcionarios f where f.user_id = (select auth.uid())
    )
  )
);

drop policy if exists "recepcao e gerente agendam" on public.agendamentos;
create policy "recepcao e gerente agendam"
on public.agendamentos for insert to authenticated
with check (
  (select public.perfil_atual()) in ('operador', 'gerente')
  and criado_por = (select auth.uid())
);

-- 5. Regra: só pode existir um gerente
create or replace function public.garantir_gerente_unico()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.raw_app_meta_data ->> 'perfil' = 'gerente' then
    if exists (
      select 1 from auth.users u
      where u.raw_app_meta_data ->> 'perfil' = 'gerente'
        and u.id <> new.id
    ) then
      raise exception 'Já existe um gerente cadastrado. Altere o perfil do atual antes de definir outro.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists gerente_unico on auth.users;
create trigger gerente_unico
before insert or update of raw_app_meta_data on auth.users
for each row execute function public.garantir_gerente_unico();