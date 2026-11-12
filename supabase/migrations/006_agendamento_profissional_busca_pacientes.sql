-- =====================================================================
-- 006_agendamento_profissional_busca_pacientes.sql
-- Agendamento pelo profissional vinculado e consultas de pacientes.
-- Rode depois das migrations 001 a 005.
-- =====================================================================

drop policy if exists "recepcao e gerente agendam" on public.agendamentos;
drop policy if exists "recepcao profissional e gerente agendam" on public.agendamentos;
create policy "recepcao profissional e gerente agendam"
on public.agendamentos for insert to authenticated
with check (
  (
    (select public.perfil_atual()) in ('operador', 'gerente')
    or (
      (select public.perfil_atual()) = 'profissional'
      and exists (
        select 1
        from public.funcionarios f
        where f.id = agendamentos.profissional_id
          and f.user_id = (select auth.uid())
          and f.ativo
          and f.atende
      )
    )
  )
  and criado_por = (select auth.uid())
  and status = 'agendado'
  and chegada_em is null
  and iniciado_em is null
  and finalizado_em is null
  and observacoes_administrativas = ''
);

create or replace function public.buscar_pacientes_para_agendamento(p_busca text)
returns table (id uuid, nome text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_perfil text := public.perfil_atual();
  v_busca text := trim(coalesce(p_busca, ''));
begin
  if v_perfil not in ('operador', 'gerente', 'profissional') then
    raise exception 'Seu perfil não pode agendar pacientes' using errcode = '42501';
  end if;

  if v_perfil = 'profissional' and not exists (
    select 1
    from public.funcionarios f
    where f.user_id = (select auth.uid())
      and f.ativo
      and f.atende
  ) then
    raise exception 'Seu usuário não está vinculado a um profissional ativo'
      using errcode = '42501';
  end if;

  if length(v_busca) < 2 then
    raise exception 'Digite ao menos duas letras para pesquisar';
  end if;

  return query
  select p.id, p.nome
  from public.pacientes p
  where strpos(lower(p.nome), lower(v_busca)) > 0
  order by p.nome
  limit 30;
end;
$$;

create or replace function public.listar_pacientes_com_proxima_consulta()
returns table (
  paciente_id uuid,
  nome text,
  cpf text,
  telefone text,
  proxima_consulta timestamptz,
  profissional_proxima_consulta text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_perfil text := public.perfil_atual();
begin
  if v_perfil not in ('operador', 'administrativo', 'gerente', 'profissional') then
    raise exception 'Seu perfil não pode consultar pacientes' using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.nome,
    coalesce(p.cpf, ''),
    coalesce(p.telefone, ''),
    proxima.data_hora,
    proxima.profissional
  from public.pacientes p
  left join lateral (
    select a.data_hora, f.nome as profissional
    from public.agendamentos a
    join public.funcionarios f on f.id = a.profissional_id
    where a.paciente_id = p.id
      and a.status = 'agendado'
      and a.data_hora >= now()
      and (
        v_perfil <> 'profissional'
        or f.user_id = (select auth.uid())
      )
    order by a.data_hora
    limit 1
  ) proxima on true
  where v_perfil <> 'profissional'
     or exists (
       select 1
       from public.agendamentos proprio
       join public.funcionarios f on f.id = proprio.profissional_id
       where proprio.paciente_id = p.id
         and f.user_id = (select auth.uid())
     )
  order by p.nome;
end;
$$;

revoke all on function public.buscar_pacientes_para_agendamento(text) from public, anon;
revoke all on function public.listar_pacientes_com_proxima_consulta() from public, anon;
grant execute on function public.buscar_pacientes_para_agendamento(text) to authenticated;
grant execute on function public.listar_pacientes_com_proxima_consulta() to authenticated;
