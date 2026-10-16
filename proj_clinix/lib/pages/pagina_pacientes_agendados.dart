import 'package:flutter/material.dart';

import '../models/agenda_clinix.dart';
import '../widgets/componentes_atendimento.dart';
import '../models/modelos_atendimento.dart';

class PaginaPacientesAgendados extends StatefulWidget {
  const PaginaPacientesAgendados({
    super.key,
    required this.agenda,
    required this.aoNovoAgendamento,
    this.diaInicial,
  });

  final AgendaClinix agenda;
  final VoidCallback aoNovoAgendamento;
  final DateTime? diaInicial;

  @override
  State<PaginaPacientesAgendados> createState() => _EstadoPacientesAgendados();
}

class _EstadoPacientesAgendados extends State<PaginaPacientesAgendados> {
  late DateTime _dia = widget.diaInicial ?? widget.agenda.agora;

  Future<void> _selecionarDia() async {
    final escolhido = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: _dia,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Visualizar agenda',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (escolhido != null && mounted) setState(() => _dia = escolhido);
  }

  @override
  Widget build(BuildContext context) {
    final itens =
        widget.agenda.agendamentos
            .where(
              (item) =>
                  mesmoDia(item.dataHora, _dia) &&
                  item.status == StatusAtendimento.agendado,
            )
            .toList()
          ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

    return ListView(
      key: const PageStorageKey('lista-pacientes-agendados'),
      padding: const EdgeInsets.all(24),
      children: [
        CabecalhoAtendimento(
          titulo: 'Pacientes agendados',
          descricao: 'Consulte a agenda e confirme a chegada para incluir o paciente na fila.',
          acao: FilledButton.icon(
            onPressed: widget.aoNovoAgendamento,
            icon: const Icon(Icons.add),
            label: const Text('Novo agendamento'),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton.outlined(
              tooltip: 'Dia anterior',
              onPressed: () => setState(
                () => _dia = DateTime(_dia.year, _dia.month, _dia.day - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            OutlinedButton.icon(
              onPressed: _selecionarDia,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(formatarData(_dia)),
            ),
            IconButton.outlined(
              tooltip: 'Próximo dia',
              onPressed: () => setState(
                () => _dia = DateTime(_dia.year, _dia.month, _dia.day + 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
            TextButton(
              onPressed: () => setState(() => _dia = widget.agenda.agora),
              child: const Text('Hoje'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('${itens.length} agendamento(s) aguardando chegada'),
        const SizedBox(height: 16),
        if (itens.isEmpty)
          const EstadoVazioAtendimento(
            titulo: 'Nenhum paciente agendado neste dia',
            descricao: 'Escolha outra data ou realize um novo agendamento.',
          ),
        for (final item in itens)
          CartaoAgendamento(
            agendamento: item,
            acao: FilledButton.icon(
              key: ValueKey('chegada-${item.id}'),
              onPressed: mesmoDia(item.dataHora, widget.agenda.agora)
                  ? () {
                      try {
                        widget.agenda.confirmarChegada(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Chegada confirmada. Paciente na fila.',
                            ),
                          ),
                        );
                      } catch (erro) {
                        mostrarErroAtendimento(context, erro);
                      }
                    }
                  : null,
              icon: const Icon(Icons.how_to_reg_outlined, size: 18),
              label: const Text('Confirmar chegada'),
            ),
          ),
        if (itens.isNotEmpty && !mesmoDia(_dia, widget.agenda.agora)) ...[
          const SizedBox(height: 8),
          const Text('A chegada pode ser confirmada no dia do agendamento.'),
        ],
      ],
    );
  }
}
