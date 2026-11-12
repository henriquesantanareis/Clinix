-- =====================================================================
-- 005_liberacao_gerente_funcionarios.sql
-- Solicitações de acesso aprovadas pelo gerente e cadastro/vínculo de
-- funcionários por e-mail. Rode depois das migrations 001 a 004.
-- =====================================================================

alter table public.funcionarios
  add column if not exists email text;

alter table public.funcionarios
  drop constraint if exists funcionarios_email_check;
alter table public.funcionarios
  add constraint funcionarios_email_check
  check (email is null or (email = lower(trim(email)) and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'));

create unique index if not exists funcionarios_email_unico
  on public.funcionarios (email)
  where email is not null;

create table if not exists public.solicitacoes_acesso (
  usuario_id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  email text not null,
  status text not null default 'pendente'
    check (status in ('pendente', 'aprovado', 'rejeitado')),
  perfil_aprovado text
    check (perfil_aprovado is null or perfil_aprovado in ('operador', 'administrativo', 'profissional')),
  criada_em timestamptz not null default now(),
  decidida_em timestamptz,
  decidida_por uuid references auth.users(id) on delete set null
);

alter table public.solicitacoes_acesso enable row level security;
revoke all on public.solicitacoes_acesso from anon, authenticated;
grant select on public.solicitacoes_acesso to authenticated;

drop policy if exists "usuario ou gerente le solicitacoes" on public.solicitacoes_acesso;
create policy "usuario ou gerente le solicitacoes"
on public.solicitacoes_acesso for select to authenticated
using (
  usuario_id = (select auth.uid())
  or (select public.perfil_atual()) = 'gerente'
);

create or replace function public.registrar_solicitacao_acesso()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_perfil text := new.raw_app_meta_data ->> 'perfil';
  v_email text := lower(coalesce(new.email, ''));
begin
  if v_email <> '' then
    update public.funcionarios
    set user_id = new.id
    where email = v_email
      and user_id is null
      and not exists (
        select 1 from public.funcionarios vinculado where vinculado.user_id = new.id
      );
  end if;

  if coalesce(v_perfil, '') not in
    ('operador', 'administrativo', 'profissional', 'gerente') then
    insert into public.solicitacoes_acesso (usuario_id, nome, email)
    values (
      new.id,
      coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
        nullif(v_email, ''),
        'Usuário'
      ),
      v_email
    )
    on conflict (usuario_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists registrar_solicitacao_acesso on auth.users;
create trigger registrar_solicitacao_acesso
after insert on auth.users
for each row execute function public.registrar_solicitacao_acesso();

revoke all on function public.registrar_solicitacao_acesso() from public, anon, authenticated;

-- Inclui contas antigas sem perfil, criadas antes desta migration.
insert into public.solicitacoes_acesso (usuario_id, nome, email, criada_em)
select
  u.id,
  coalesce(
    nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
    nullif(lower(u.email), ''),
    'Usuário'
  ),
  lower(coalesce(u.email, '')),
  u.created_at
from auth.users u
where coalesce(u.raw_app_meta_data ->> 'perfil', '') not in
  ('operador', 'administrativo', 'profissional', 'gerente')
on conflict (usuario_id) do nothing;

-- Vincula contas existentes aos funcionários com o mesmo e-mail.
update public.funcionarios f
set user_id = u.id
from auth.users u
where f.user_id is null
  and f.email = lower(u.email)
  and not exists (
    select 1 from public.funcionarios outro where outro.user_id = u.id
  );

create or replace function public.aprovar_solicitacao_acesso(
  p_usuario_id uuid,
  p_perfil text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.perfil_atual() <> 'gerente' then
    raise exception 'Somente o gerente pode aprovar acessos' using errcode = '42501';
  end if;

  if p_perfil is null
     or p_perfil not in ('operador', 'administrativo', 'profissional') then
    raise exception 'Perfil de aprovação inválido';
  end if;

  perform 1
  from public.solicitacoes_acesso
  where usuario_id = p_usuario_id and status = 'pendente'
  for update;
  if not found then
    raise exception 'A solicitação não existe ou já foi decidida';
  end if;

  update auth.users
  set raw_app_meta_data =
    coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('perfil', p_perfil)
  where id = p_usuario_id;
  if not found then
    raise exception 'A conta do usuário não foi encontrada';
  end if;

  update public.solicitacoes_acesso
  set status = 'aprovado',
      perfil_aprovado = p_perfil,
      decidida_em = now(),
      decidida_por = auth.uid()
  where usuario_id = p_usuario_id;
end;
$$;

create or replace function public.rejeitar_solicitacao_acesso(p_usuario_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.perfil_atual() <> 'gerente' then
    raise exception 'Somente o gerente pode rejeitar acessos' using errcode = '42501';
  end if;

  update public.solicitacoes_acesso
  set status = 'rejeitado',
      decidida_em = now(),
      decidida_por = auth.uid()
  where usuario_id = p_usuario_id and status = 'pendente';
  if not found then
    raise exception 'A solicitação não existe ou já foi decidida';
  end if;
end;
$$;

create or replace function public.cadastrar_funcionario(
  p_nome text,
  p_email text,
  p_cargo text,
  p_atende boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := nullif(lower(trim(p_email)), '');
  v_id uuid;
begin
  if public.perfil_atual() <> 'gerente' then
    raise exception 'Somente o gerente pode cadastrar funcionários' using errcode = '42501';
  end if;

  if nullif(trim(p_nome), '') is null then
    raise exception 'Informe o nome do funcionário';
  end if;

  if v_email is not null and exists (
    select 1
    from auth.users u
    join public.funcionarios f on f.user_id = u.id
    where lower(u.email) = v_email
  ) then
    raise exception 'Esta conta já está vinculada a outro funcionário';
  end if;

  insert into public.funcionarios (nome, email, cargo, atende, user_id)
  values (
    trim(p_nome),
    v_email,
    coalesce(trim(p_cargo), ''),
    coalesce(p_atende, false),
    (
      select u.id from auth.users u
      where v_email is not null
        and lower(u.email) = v_email
        and not exists (
          select 1 from public.funcionarios f where f.user_id = u.id
        )
      limit 1
    )
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.aprovar_solicitacao_acesso(uuid, text) from public, anon;
revoke all on function public.rejeitar_solicitacao_acesso(uuid) from public, anon;
revoke all on function public.cadastrar_funcionario(text, text, text, boolean) from public, anon;
grant execute on function public.aprovar_solicitacao_acesso(uuid, text) to authenticated;
grant execute on function public.rejeitar_solicitacao_acesso(uuid) to authenticated;
grant execute on function public.cadastrar_funcionario(text, text, text, boolean) to authenticated;
