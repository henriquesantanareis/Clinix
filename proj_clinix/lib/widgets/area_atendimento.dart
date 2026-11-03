import 'package:flutter/material.dart';

import '../models/agenda_clinix.dart';
import 'componentes_clinix.dart';
import '../pages/pagina_agendamento.dart';
import '../pages/pagina_atendimento.dart';
import '../pages/pagina_cadastro_paciente.dart';
import '../pages/pagina_fila_espera.dart';
import '../pages/pagina_pacientes_agendados.dart';

enum _AbaClinix {
  agenda('Agenda', Icons.calendar_month_outlined),
  cadastro('Cadastrar', Icons.person_add_alt_1_outlined),
  fila('Fila', Icons.people_outline),
  agendamento('Agendar', Icons.add_circle_outline),
  atendimento('Atender', Icons.medical_services_outlined);

  const _AbaClinix(this.rotulo, this.icone);
  final String rotulo;
  final IconData icone;
}

class AreaAtendimento extends StatefulWidget {
  const AreaAtendimento({super.key, required this.agenda, this.aoVoltar});

  final AgendaClinix agenda;
  final VoidCallback? aoVoltar;

  @override
  State<AreaAtendimento> createState() => _EstadoAreaAtendimento();
}

class _EstadoAreaAtendimento extends State<AreaAtendimento> {
  _AbaClinix _aba = _AbaClinix.agenda;
  DateTime? _diaAgenda;
  int _versaoAgenda = 0;
  int _versaoPacientes = 0;

  void _abrirAgendamento() => setState(() => _aba = _AbaClinix.agendamento);

  // Volta para a Agenda, incrementando a versão de pacientes para forçar a atualização da lista.
  void _voltarDoCadastro() => setState(() {
    _versaoPacientes++;
    _aba = _AbaClinix.agenda;
  });

  Widget _pagina(_AbaClinix aba) => switch (aba) {
    _AbaClinix.agenda => PaginaPacientesAgendados(
      key: ValueKey('agenda-$_versaoAgenda'),
      agenda: widget.agenda,
      diaInicial: _diaAgenda,
      aoNovoAgendamento: _abrirAgendamento,
    ),
    _AbaClinix.cadastro => PaginaCadastroPaciente(aoSalvar: _voltarDoCadastro),
    _AbaClinix.fila => PaginaFilaEspera(agenda: widget.agenda),
    _AbaClinix.agendamento => PaginaAgendamento(
      key: ValueKey('agendamento-$_versaoPacientes'),
      agenda: widget.agenda,
      aoAgendar: (dataHora) => setState(() {
        _diaAgenda = dataHora;
        _versaoAgenda++;
        _aba = _AbaClinix.agenda;
      }),
    ),
    _AbaClinix.atendimento => PaginaAtendimento(agenda: widget.agenda),
  };

  @override
  Widget build(BuildContext context) {
    final abas = [
      _AbaClinix.agenda,
      if (widget.agenda.perfil.podeCadastrarPaciente) _AbaClinix.cadastro,
      if (widget.agenda.perfil.podeVerFila) _AbaClinix.fila,
      if (widget.agenda.perfil.podeAgendar) _AbaClinix.agendamento,
      if (widget.agenda.perfil.podeAtender) _AbaClinix.atendimento,
    ];
    // Se a aba atual não estiver disponível para o perfil, mostra a primeira.
    final atual = abas.contains(_aba) ? _aba : abas.first;
    final indice = abas.indexOf(atual);

    return Scaffold(
      appBar: AppBar(
        leading: widget.aoVoltar == null
            ? null
            : BackButton(onPressed: widget.aoVoltar),
        title: const MarcaClinix(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: Text(widget.agenda.perfil.rotulo)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: widget.agenda,
                builder: (context, _) => IndexedStack(
                  index: indice,
                  children: [for (final aba in abas) _pagina(aba)],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (value) => setState(() => _aba = abas[value]),
        destinations: [
          for (final aba in abas)
            NavigationDestination(
              key: ValueKey('nav-${aba.name}'),
              icon: Icon(aba.icone),
              label: aba.rotulo,
            ),
        ],
      ),
    );
  }
}
