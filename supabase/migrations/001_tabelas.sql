-- =====================================================================
-- 001_tabelas.sql
-- Estrutura inicial do Clinix: funcionários, pacientes, agendamentos e fila.
-- Rode uma vez, em um banco vazio, na ordem deste arquivo.
-- Para alterações futuras, crie um novo arquivo (002_..., 003_...).
-- Políticas de RLS e auditoria ficam em arquivos separados.
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
  cep text not null default '',
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
  observacoes text not null default '',
  status status_atendimento not null default 'agendado',
  chegada_em timestamptz,
  iniciado_em timestamptz,
  finalizado_em timestamptz,
  anotacoes text not null default '',
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

-- 6. View da fila: agendamentos aguardando, com nomes para a equipe administrativa.
-- security_invoker faz a view respeitar o RLS das tabelas de origem.
-- A ordenação fica na consulta do app (order by chegada).
create view public.fila_espera with (security_invoker = true) as
select
  a.id,
  p.nome as paciente,
  f.nome as profissional,
  a.data_hora as horario,
  a.chegada_em as chegada
from public.agendamentos a
join public.pacientes p on p.id = a.paciente_id
join public.funcionarios f on f.id = a.profissional_id
where a.status = 'aguardando';