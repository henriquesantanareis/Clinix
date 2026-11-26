-- =====================================================================
-- 007_recuperacao_senha.sql
-- Recuperacao de senha para contas cadastradas no banco, sem envio de e-mail.
-- Rode depois da migration 006.
-- =====================================================================

create extension if not exists pgcrypto;

create table if not exists public.solicitacoes_recuperacao_senha (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid references auth.users(id) on delete set null,
  email text not null,
  status text not null default 'pendente'
    check (status in ('pendente', 'concluida', 'cancelada')),
  criada_em timestamptz not null default now(),
  concluida_em timestamptz,
  concluida_por uuid references auth.users(id) on delete set null
);

alter table public.solicitacoes_recuperacao_senha enable row level security;
revoke all on public.solicitacoes_recuperacao_senha from anon, authenticated;
grant select on public.solicitacoes_recuperacao_senha to authenticated;

drop policy if exists "gerente gerencia recuperacoes" on public.solicitacoes_recuperacao_senha;
create policy "gerente gerencia recuperacoes"
on public.solicitacoes_recuperacao_senha for all to authenticated
using ((select public.perfil_atual()) = 'gerente')
with check ((select public.perfil_atual()) = 'gerente');

create or replace function public.solicitar_recuperacao_senha(p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(trim(coalesce(p_email, '')));
  v_usuario_id uuid;
begin
  if v_email = '' then
    raise exception 'Informe o e-mail';
  end if;

  select id into v_usuario_id
  from auth.users
  where lower(coalesce(email, '')) = v_email
  limit 1;

  if v_usuario_id is not null then
    insert into public.solicitacoes_recuperacao_senha (usuario_id, email)
    values (v_usuario_id, v_email);
  end if;
end;
$$;

create or replace function public.alterar_senha_usuario(
  p_usuario_id uuid,
  p_senha text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.perfil_atual() <> 'gerente' then
    raise exception 'Somente o gerente pode alterar senhas'
      using errcode = '42501';
  end if;

  if length(coalesce(p_senha, '')) < 8 then
    raise exception 'Use pelo menos 8 caracteres';
  end if;

  update auth.users
  set encrypted_password = extensions.crypt(p_senha, extensions.gen_salt('bf')),
      updated_at = now()
  where id = p_usuario_id;

  if not found then
    raise exception 'A conta do usuário não foi encontrada';
  end if;
end;
$$;

create or replace function public.concluir_recuperacao_senha(
  p_solicitacao_id uuid,
  p_senha text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario_id uuid;
begin
  if public.perfil_atual() <> 'gerente' then
    raise exception 'Somente o gerente pode concluir recuperacoes'
      using errcode = '42501';
  end if;

  select usuario_id into v_usuario_id
  from public.solicitacoes_recuperacao_senha
  where id = p_solicitacao_id and status = 'pendente'
  for update;

  if not found then
    raise exception 'Solicitacao inexistente ou ja concluida';
  end if;
  if v_usuario_id is null then
    raise exception 'A conta vinculada a esta solicitacao nao existe';
  end if;

  perform public.alterar_senha_usuario(v_usuario_id, p_senha);

  update public.solicitacoes_recuperacao_senha
  set status = 'concluida',
      concluida_em = now(),
      concluida_por = auth.uid()
  where id = p_solicitacao_id;
end;
$$;

create or replace function public.cancelar_recuperacao_senha(
  p_solicitacao_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.perfil_atual() <> 'gerente' then
    raise exception 'Somente o gerente pode cancelar recuperacoes'
      using errcode = '42501';
  end if;

  update public.solicitacoes_recuperacao_senha
  set status = 'cancelada',
      concluida_em = now(),
      concluida_por = auth.uid()
  where id = p_solicitacao_id and status = 'pendente';

  if not found then
    raise exception 'Solicitacao inexistente ou ja decidida';
  end if;
end;
$$;

revoke all on function public.solicitar_recuperacao_senha(text) from public;
grant execute on function public.solicitar_recuperacao_senha(text) to anon, authenticated;

revoke all on function public.alterar_senha_usuario(uuid, text) from public, anon;
revoke all on function public.concluir_recuperacao_senha(uuid, text) from public, anon;
revoke all on function public.cancelar_recuperacao_senha(uuid) from public, anon;
grant execute on function public.alterar_senha_usuario(uuid, text) to authenticated;
grant execute on function public.concluir_recuperacao_senha(uuid, text) to authenticated;
grant execute on function public.cancelar_recuperacao_senha(uuid) to authenticated;
