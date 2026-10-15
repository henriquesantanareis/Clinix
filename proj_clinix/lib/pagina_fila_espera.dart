import 'package:flutter/material.dart';

import 'agenda_clinix.dart';
import 'componentes_atendimento.dart';
import 'modelos_atendimento.dart';

class PaginaFilaEspera extends StatefulWidget {
  const PaginaFilaEspera({super.key, required this.agenda});

  final AgendaClinix agenda;

  @override
  State<PaginaFilaEspera> createState() => _EstadoFilaEspera();
}

class _EstadoFilaEspera extends State<PaginaFilaEspera> {
  StatusAtendimento _filtro = StatusAtendimento.aguardando;

  @override
  Widget build(BuildContext context) {
    if (!widget.agenda.perfil.podeVerFila) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: EstadoVazioAtendimento(
          titulo: 'Acesso restrito',
          descricao: 'A fila está disponível para gerente e administrador.',
          icone: Icons.lock_outline,
        ),
      );
    }

    final todos = widget.agenda.agendamentos;
    final itens = todos.where((item) => item.status == _filtro).toList()
      ..sort((a, b) {
        if (_filtro == StatusAtendimento.finalizado) {
          return b.finalizadoEm!.compareTo(a.finalizadoEm!);
        }
        return (a.chegadaEm ?? a.dataHora).compareTo(b.chegadaEm ?? b.dataHora);
      });

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CabecalhoAtendimento(
          titulo: 'Fila de espera',
          descricao: 'Acompanhe os pacientes por etapa do atendimento.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in [
              StatusAtendimento.aguardando,
              StatusAtendimento.emAtendimento,
              StatusAtendimento.finalizado,
            ])
              ChoiceChip(
                key: ValueKey('filtro-${status.name}'),
                label: Text(
                  '${status.rotulo} (${todos.where((item) => item.status == status).length})',
                ),
                selected: _filtro == status,
                onSelected: (_) => setState(() => _filtro = status),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (itens.isEmpty)
          EstadoVazioAtendimento(
            titulo: 'Nenhum paciente nesta etapa',
            descricao:
                'Os pacientes aparecerão aqui quando estiverem na etapa ${_filtro.rotulo.toLowerCase()}.',
            icone: Icons.people_outline,
          ),
        for (final item in itens)
          CartaoAgendamento(agendamento: item, mostrarAnotacoes: true),
      ],
    );
  }
}
