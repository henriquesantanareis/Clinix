# Clinix

Aplicativo multiplataforma desenvolvido com Flutter para oferecer uma experiência simples de acesso aos serviços de saúde.

O projeto Flutter está em [`proj_clinix/`](proj_clinix/). Configure o Supabase copiando `proj_clinix/config/supabase.example.json` para `proj_clinix/config/supabase.json` e preenchendo a URL e a chave publicável. Esse arquivo é ignorado pelo Git. Depois, execute `cd proj_clinix && ./run_web.sh`.

## Tecnologias

- Flutter para a interface do aplicativo.
- Supabase Auth para cadastro e login de usuários.

## Telas de atendimento

A página inicial possui o acesso **Agenda e atendimento** para as telas de:

- Pacientes agendados e confirmação de chegada;
- Fila de espera por status;
- Formulário de agendamento;
- Atendimento com ficha, início e finalização.

Nesta entrega, os dados dessas telas são temporários e ficam na sessão, sem
persistência no Supabase. Consulte o [fluxo, os perfis e a árvore de widgets](docs/telas_atendimento.md).
