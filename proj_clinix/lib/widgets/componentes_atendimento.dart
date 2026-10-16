import 'package:flutter/material.dart';

import '../models/modelos_atendimento.dart';

class CabecalhoAtendimento extends StatelessWidget {
  const CabecalhoAtendimento({
    super.key,
    required this.titulo,
    required this.descricao,
    this.acao,
  });

  final String titulo;
  final String descricao;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF183D37),
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(descricao, style: const TextStyle(color: Color(0xFF687771))),
        if (acao != null) ...[const SizedBox(height: 16), acao!],
      ],
    ),
  );
}

class EstadoVazioAtendimento extends StatelessWidget {
  const EstadoVazioAtendimento({
    super.key,
    required this.titulo,
    required this.descricao,
    this.icone = Icons.event_available_outlined,
    this.acao,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDCE3DD)),
    ),
    child: Column(
      children: [
        Icon(icone, size: 40, color: const Color(0xFF167A68)),
        const SizedBox(height: 16),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          descricao,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF687771)),
        ),
        if (acao != null) ...[const SizedBox(height: 20), acao!],
      ],
    ),
  );
}

class IndicadorStatus extends StatelessWidget {
  const IndicadorStatus(this.status, {super.key});

  final StatusAtendimento status;

  @override
  Widget build(BuildContext context) {
    final cor = switch (status) {
      StatusAtendimento.agendado => const Color(0xFF315A90),
      StatusAtendimento.aguardando => const Color(0xFF875900),
      StatusAtendimento.emAtendimento => const Color(0xFF684593),
      StatusAtendimento.finalizado => const Color(0xFF167A68),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.rotulo,
        style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class CartaoAgendamento extends StatelessWidget {
  const CartaoAgendamento({
    super.key,
    required this.agendamento,
    this.acao,
    this.mostrarAnotacoes = false,
  });

  final AgendamentoClinix agendamento;
  final Widget? acao;
  final bool mostrarAnotacoes;

  @override
  Widget build(BuildContext context) {
    final item = agendamento;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDCE3DD)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${formatarData(item.dataHora)} · ${formatarHora(item.dataHora)}',
                  style: const TextStyle(
                    color: Color(0xFF167A68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IndicadorStatus(item.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.paciente.nome,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text('Profissional: ${item.profissional}'),
            if (item.chegadaEm != null) ...[
              const SizedBox(height: 6),
              Text('Chegada: ${formatarHora(item.chegadaEm!)}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => mostrarFichaPaciente(
                    context,
                    item,
                    mostrarAnotacoes: mostrarAnotacoes,
                  ),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Ficha do paciente'),
                ),
                ?acao,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DadosFichaPaciente extends StatelessWidget {
  const DadosFichaPaciente({
    super.key,
    required this.agendamento,
    this.mostrarAnotacoes = false,
  });

  final AgendamentoClinix agendamento;
  final bool mostrarAnotacoes;

  @override
  Widget build(BuildContext context) {
    final item = agendamento;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.paciente.nome, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(
          'Telefone: ${item.paciente.telefone.isEmpty ? 'Não informado' : item.paciente.telefone}',
        ),
        const SizedBox(height: 8),
        Text('Profissional: ${item.profissional}'),
        const SizedBox(height: 8),
        Text(
          'Agendamento: ${formatarData(item.dataHora)} às ${formatarHora(item.dataHora)}',
        ),
        const SizedBox(height: 12),
        IndicadorStatus(item.status),
        if (item.observacoes.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Observações do agendamento',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(item.observacoes),
        ],
        if (mostrarAnotacoes && item.anotacoes.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Anotações do atendimento',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(item.anotacoes),
        ],
      ],
    );
  }
}

Future<void> mostrarFichaPaciente(
  BuildContext context,
  AgendamentoClinix item, {
  bool mostrarAnotacoes = false,
}) => showDialog<void>(
  context: context,
  useRootNavigator: false,
  builder: (context) => AlertDialog(
    title: const Text('Ficha do paciente'),
    scrollable: true,
    content: SizedBox(
      width: 460,
      child: DadosFichaPaciente(
        agendamento: item,
        mostrarAnotacoes: mostrarAnotacoes,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Fechar'),
      ),
    ],
  ),
);

void mostrarErroAtendimento(BuildContext context, Object erro) {
  final mensagem = switch (erro) {
    StateError erro => erro.message,
    ArgumentError erro =>
      erro.message?.toString() ?? 'Confira os dados informados.',
    _ => 'Não foi possível concluir a ação. Tente novamente.',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}
