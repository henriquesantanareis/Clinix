-- =====================================================================
-- 004_telefone_obrigatorio.sql
-- O telefone é obrigatório no cadastro de paciente, com DDD e 10 ou 11 números.
-- Rode depois do 003, em banco em que todo paciente já tem telefone válido.
-- =====================================================================

alter table public.pacientes
  add constraint pacientes_telefone_formato
  check (telefone ~ '^[0-9]{10,11}$');