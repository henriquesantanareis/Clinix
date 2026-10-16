import 'package:flutter/material.dart';

// import '../componentes_clinix.dart';
import '../models/agenda_clinix.dart';
import 'componentes_clinix.dart';
import '../pages/pagina_agendamento.dart';
import '../pages/pagina_atendimento.dart';
import '../pages/pagina_fila_espera.dart';
import '../pages/pagina_pacientes_agendados.dart';

enum _AbaClinix {
  pacientes('Agenda', Icons.calendar_month_outlined),
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
  _AbaClinix _aba = _AbaClinix.pacientes;
  DateTime? _diaAgenda;
  int _versaoAgenda = 0;

  void _abrirAgendamento() => setState(() => _aba = _AbaClinix.agendamento);

  Widget _pagina(_AbaClinix aba) => switch (aba) {
    _AbaClinix.pacientes => PaginaPacientesAgendados(
      key: ValueKey('pacientes-$_versaoAgenda'),
      agenda: widget.agenda,
      diaInicial: _diaAgenda,
      aoNovoAgendamento: _abrirAgendamento,
    ),
    _AbaClinix.fila => PaginaFilaEspera(agenda: widget.agenda),
    _AbaClinix.agendamento => PaginaAgendamento(
      agenda: widget.agenda,
      aoAgendar: (dataHora) => setState(() {
        _diaAgenda = dataHora;
        _versaoAgenda++;
        _aba = _AbaClinix.pacientes;
      }),
    ),
    _AbaClinix.atendimento => PaginaAtendimento(agenda: widget.agenda),
  };

  @override
  Widget build(BuildContext context) {
    final abas = [
      _AbaClinix.pacientes,
      if (widget.agenda.perfil.podeVerFila) _AbaClinix.fila,
      _AbaClinix.agendamento,
      if (widget.agenda.perfil.podeAtender) _AbaClinix.atendimento,
    ];
    final indice = abas.indexOf(_aba);
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
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF1DA),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: const Text(
                  'Dados temporários: ficam nesta sessão e não são salvos no banco.',
                  style: TextStyle(color: Color(0xFF684B17), fontSize: 12),
                ),
              ),
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
