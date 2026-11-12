# Clinix

Aplicativo multiplataforma desenvolvido com Flutter para oferecer uma experiência simples de acesso aos serviços de saúde.

## Tecnologias

- Flutter para a interface do aplicativo.
- Supabase Auth para cadastro e login de usuários.

## Telas de atendimento

A página inicial possui o acesso **Agenda e atendimento** para as telas de:

- Pacientes agendados e confirmação de chegada;
- Fila de espera por status;
- Formulário de agendamento;
- Atendimento com ficha, início e finalização.

## Aprovação de acessos e funcionários

Novas contas ficam sem perfil até o gerente aprovar a solicitação na aba
**Aprovações → Solicitações**. O gerente pode aprovar como Operador,
Administrativo ou Profissional, ou rejeitar. A aba **Funcionários**, dentro de
**Aprovações**, cadastra os dados da equipe; ao informar um e-mail, uma conta
existente ou criada posteriormente com esse mesmo endereço é vinculada
automaticamente. O cadastro não envia convites por e-mail.

Em um banco novo, aplique as migrations `001` a `006` em ordem. Em um banco
que já tem as migrations `001` a `004`, aplique somente `005` e depois `006`;
não execute novamente a `001`, que cria tipos e tabelas. A `002` instala as
permissões e funções essenciais e precisa estar aplicada antes dessas etapas.
As migrations `005` e `006` habilitam, respectivamente, a gestão de acessos e
funcionários e o agendamento feito por profissionais.

Profissionais vinculados a um funcionário ativo podem agendar pacientes já
cadastrados somente para si. A busca de pacientes mostra a próxima consulta
futura; profissionais veem apenas pacientes que já atendem.
