import 'package:flutter/material.dart';

import 'agenda_clinix.dart';
import 'componentes_atendimento.dart';
import 'modelos_atendimento.dart';

class PaginaAtendimento extends StatelessWidget {
  const PaginaAtendimento({super.key, required this.agenda});

  final AgendaClinix agenda;

  Future<void> _finalizar(BuildContext context, AgendamentoClinix item) async {
    final anotacoes = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => _DialogoFinalizarAtendimento(agendamento: item),
    );
    if (anotacoes == null || !context.mounted) return;
    try {
      agenda.finalizarAtendimento(item.id, anotacoes: anotacoes);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Atendimento finalizado.')));
    } catch (erro) {
      mostrarErroAtendimento(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!agenda.perfil.podeAtender) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: EstadoVazioAtendimento(
          titulo: 'Acesso restrito',
          descricao:
              'O atendimento está disponível para gerente e administrador.',
          icone: Icons.lock_outline,
        ),
      );
    }
    final itens =
        agenda.agendamentos
            .where(
              (item) =>
                  item.status == StatusAtendimento.aguardando ||
                  item.status == StatusAtendimento.emAtendimento,
            )
            .toList()
          ..sort((a, b) {
            if (a.status != b.status) {
              return a.status == StatusAtendimento.emAtendimento ? -1 : 1;
            }
            return a.chegadaEm!.compareTo(b.chegadaEm!);
          });

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CabecalhoAtendimento(
          titulo: 'Atendimento',
          descricao: 'Consulte a fila, abra a ficha do paciente e registre o início e a conclusão.',
        ),
        if (itens.isEmpty)
          const EstadoVazioAtendimento(
            titulo: 'Nenhum atendimento pendente',
            descricao: 'Confirme a chegada de um paciente na agenda para iniciar o atendimento.',
            icone: Icons.medical_services_outlined,
          ),
        for (final item in itens)
          CartaoAgendamento(
            agendamento: item,
            mostrarAnotacoes: true,
            acao: item.status == StatusAtendimento.aguardando
                ? FilledButton.icon(
                    key: ValueKey('iniciar-${item.id}'),
                    onPressed: () {
                      try {
                        agenda.iniciarAtendimento(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Atendimento iniciado.'),
                          ),
                        );
                      } catch (erro) {
                        mostrarErroAtendimento(context, erro);
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Iniciar atendimento'),
                  )
                : FilledButton.icon(
                    key: ValueKey('finalizar-${item.id}'),
                    onPressed: () => _finalizar(context, item),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Finalizar atendimento'),
                  ),
          ),
      ],
    );
  }
}

class _DialogoFinalizarAtendimento extends StatefulWidget {
  const _DialogoFinalizarAtendimento({required this.agendamento});

  final AgendamentoClinix agendamento;

  @override
  State<_DialogoFinalizarAtendimento> createState() =>
      _EstadoDialogoFinalizar();
}

class _EstadoDialogoFinalizar extends State<_DialogoFinalizarAtendimento> {
  final _anotacoes = TextEditingController();

  @override
  void dispose() {
    _anotacoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Finalizar atendimento'),
    scrollable: true,
    content: SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DadosFichaPaciente(agendamento: widget.agendamento),
          const SizedBox(height: 24),
          TextField(
            key: const Key('anotacoes-atendimento'),
            controller: _anotacoes,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Anotações do atendimento (opcional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Voltar'),
      ),
      FilledButton(
        key: const Key('confirmar-finalizacao'),
        onPressed: () => Navigator.of(context).pop(_anotacoes.text.trim()),
        child: const Text('Confirmar finalização'),
      ),
    ],
  );
}
