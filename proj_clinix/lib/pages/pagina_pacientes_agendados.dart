import 'package:flutter/material.dart';

import '../data/agenda_repository.dart';
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
  final AgendaRepository _repositorio = AgendaRepository();
  late DateTime _dia = widget.diaInicial ?? widget.agenda.agora;
  List<AgendamentoClinix> _itens = [];
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState((){
      _carregando = true;
      _erro = null;
    });
    try{
      final todos = await _repositorio.listarAgenda(_dia);
      final pendentes =  todos.where((item) => item.status == StatusAtendimento.agendado).toList()..sort((a, b) => a.dataHora.compareTo(b.dataHora));
      if (!mounted) return;
      setState(() => _itens = pendentes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar a agenda. Tente de novo.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mudarDia(DateTime novo) {
    _dia = DateTime(novo.year, novo.month, novo.day);
    _carregar();
  }

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
    if (escolhido != null && mounted) _mudarDia(escolhido);
  }

  Future<void> _confirmarChegada(AgendamentoClinix item) async {
    try {
      await _repositorio.registrarChegada(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chegada confirmada. Paciente na fila.'),),
      );
      await _carregar();
    } catch (erro) {
      if (!mounted) return;
      mostrarErroAtendimento(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = widget.agenda.agora;

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
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
                onPressed: () => _mudarDia(DateTime(_dia.year, _dia.month, _dia.day - 1)),
                icon: const Icon(Icons.chevron_left),
              ),
              OutlinedButton.icon(
                onPressed: _selecionarDia,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(formatarData(_dia)),
              ),
              IconButton.outlined(
                tooltip: 'Próximo dia',
                onPressed: () => _mudarDia(DateTime(_dia.year, _dia.month, _dia.day + 1)),
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(
                onPressed: () => _mudarDia(hoje),
                child: const Text('Hoje'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_carregando && _itens.isEmpty && _erro == null)
            const EstadoVazioAtendimento(
              titulo: 'Nenhum paciente agendado neste dia',
              descricao: 'Escolha outra data ou realize um novo agendamento.',
            ),
          for (final item in _itens)
            CartaoAgendamento(
              agendamento: item,
              acao: FilledButton.icon(
                key: ValueKey('chegada-${item.id}'),
                icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                label: const Text('Confirmar chegada'),
                onPressed: mesmoDia(item.dataHora, hoje)
                    ? () => _confirmarChegada(item)
                    : null,
              ),
            ),
          if (_itens.isNotEmpty && !mesmoDia(_dia, hoje)) ...[
            const SizedBox(height: 8),
            const Text('A chegada pode ser confirmada no dia do agendamento.'),
          ],
        ],
      ),
    );
  }
}
