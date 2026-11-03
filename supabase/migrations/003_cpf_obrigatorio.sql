-- =====================================================================
-- 003_cpf_obrigatorio.sql
-- O CPF é obrigatório no cadastro de paciente.
-- Rode depois do 002_politicas.sql, em banco que não tenha pacientes sem CPF.
-- =====================================================================

alter table public.pacientes alter column cpf set not null;