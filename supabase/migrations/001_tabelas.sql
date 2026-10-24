-- =====================================================================
-- 001_tabelas.sql
-- Estrutura do Clinix: tipo de status, funcionários, pacientes,
-- agendamentos, sincronização de status e view da fila.
-- Rode uma vez, em um banco vazio, na ordem deste arquivo.
-- Funções, auditoria e políticas de RLS ficam em 002_politicas.sql.
-- =====================================================================

-- 1. Tipo de status do atendimento
create type status_atendimento as enum
  ('agendado', 'aguardando', 'em_atendimento', 'finalizado', 'cancelado');

-- 2. Funcionários (todas as pessoas da clínica, com ou sem login)
create table public.funcionarios (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete set null,
  nome text not null,
  cargo text not null default '',
  atende boolean not null default false,
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  constraint funcionarios_nome_check check (length(trim(nome)) > 0)
);

alter table public.funcionarios enable row level security;

-- 3. Pacientes (fictícios neste projeto)
create table public.pacientes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cpf text unique,
  telefone text not null default '',
  cep text,
  logradouro text,
  numero text,
  complemento text,
  bairro text,
  cidade text,
  uf char(2),
  created_at timestamptz not null default now(),
  constraint pacientes_nome_check check (length(trim(nome)) > 0),
  constraint pacientes_cpf_formato check (cpf is null or cpf ~ '^[0-9]{11}$')
);

alter table public.pacientes enable row level security;

-- 4. Agendamentos (centro do modelo; a fila é derivada daqui)
create table public.agendamentos (
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid not null references public.pacientes(id),
  profissional_id uuid not null references public.funcionarios(id),
  criado_por uuid references auth.users(id) on delete set null default auth.uid(),
  data_hora timestamptz not null,
  observacoes_agendamento text not null default '',
  status status_atendimento not null default 'agendado',
  chegada_em timestamptz,
  iniciado_em timestamptz,
  finalizado_em timestamptz,
  observacoes_administrativas text not null default '',
  created_at timestamptz not null default now()
);

alter table public.agendamentos enable row level security;

-- 5. Índices
create index agendamentos_paciente_idx on public.agendamentos (paciente_id);
create index agendamentos_data_hora_idx on public.agendamentos (data_hora);

-- Regra: um profissional não tem dois atendimentos no mesmo horário.
-- Cancelados ficam fora, para liberar a vaga.
create unique index horario_unico_por_profissional
  on public.agendamentos (profissional_id, data_hora)
  where status <> 'cancelado';

-- Regra: um profissional tem no máximo um atendimento em andamento.
create unique index um_atendimento_por_profissional
  on public.agendamentos (profissional_id)
  where status = 'em_atendimento';

-- 6. Sincronização do status com as datas. O status não é preenchido
-- pelo app: ele acompanha chegada_em, iniciado_em e finalizado_em.
create or replace function public.sincronizar_status_atendimento()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.finalizado_em is not null and new.iniciado_em is null then
    raise exception 'Um atendimento não pode ser finalizado antes de iniciado';
  end if;

  if new.finalizado_em is not null and new.status <> 'cancelado' then
    new.status := 'finalizado';
  elsif new.iniciado_em is not null and new.status in ('agendado', 'aguardando') then
    new.status := 'em_atendimento';
  elsif new.chegada_em is not null and new.status = 'agendado' then
    new.status := 'aguardando';
  end if;

  return new;
end;
$$;

drop trigger if exists sincronizar_status on public.agendamentos;
create trigger sincronizar_status
before insert or update on public.agendamentos
for each row execute function public.sincronizar_status_atendimento();

-- 7. View da fila: agendamentos aguardando ou em atendimento, com nomes.
-- security_invoker faz a view respeitar o RLS das tabelas de origem.
-- A ordenação fica na consulta do app (order by chegada).
create view public.fila_espera with (security_invoker = true) as
select
  a.id,
  p.nome as paciente,
  f.nome as profissional,
  a.data_hora as horario,
  a.chegada_em as chegada,
  a.status::text as status
from public.agendamentos a
join public.pacientes p on p.id = a.paciente_id
join public.funcionarios f on f.id = a.profissional_id
where a.status in ('aguardando', 'em_atendimento');