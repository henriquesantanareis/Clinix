import 'package:flutter/material.dart';

import '../data/agenda_repository.dart';
import '../models/agenda_clinix.dart';
import '../models/modelos_atendimento.dart';
import '../widgets/componentes_atendimento.dart';

class PaginaAtendimento extends StatefulWidget {
  const PaginaAtendimento({super.key, required this.agenda});

  final AgendaClinix agenda;

  @override
  State<PaginaAtendimento> createState() => _EstadoPaginaAtendimento();
}

class _EstadoPaginaAtendimento extends State<PaginaAtendimento> {
  final AgendaRepository _repositorio = AgendaRepository();

  List<AgendamentoClinix> _itens = [];
  bool _carregando = false;
  String? _erro;
  String? _ocupado;

  @override
  void initState() {
    super.initState();
    if (widget.agenda.perfil.podeAtender) _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final itens = await _repositorio.listarFila(widget.agenda.agora);
      if (!mounted) return;
      setState(() => _itens = itens);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar os atendimentos. Tente de novo.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _iniciar(AgendamentoClinix item) async {
    setState(() => _ocupado = item.id);
    try {
      await _repositorio.iniciarAtendimento(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atendimento iniciado.')),
      );
      await _carregar();
    } catch (erro) {
      if (mounted) mostrarErroAtendimento(context, erro);
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  Future<void> _finalizar(AgendamentoClinix item) async {
    final anotacoes = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (_) => _DialogoFinalizarAtendimento(agendamento: item),
    );
    if (anotacoes == null || !mounted) return;

    setState(() => _ocupado = item.id);
    try {
      await _repositorio.encerrarAtendimento(item.id, anotacoes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atendimento finalizado.')),
      );
      await _carregar();
    } catch (erro) {
      if (mounted) mostrarErroAtendimento(context, erro);
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.agenda.perfil.podeAtender) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: EstadoVazioAtendimento(
          titulo: 'Acesso restrito',
          descricao: 'O atendimento está disponível para profissionais e gerentes.',
          icone: Icons.lock_outline,
        ),
      );
    }

    final itens = [..._itens]
      ..sort((a, b) {
        if (a.status != b.status) {
          return a.status == StatusAtendimento.emAtendimento ? -1 : 1;
        }
        return (a.chegadaEm ?? a.dataHora).compareTo(b.chegadaEm ?? b.dataHora);
      });

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CabecalhoAtendimento(
            titulo: 'Atendimento',
            descricao: 'Consulte a fila, abra a ficha do paciente e registre o início e a conclusão.',
          ),
          if (_erro != null) ...[
            Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
          ],
          if (!_carregando && _erro == null && itens.isEmpty)
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
                      onPressed: _ocupado == null ? () => _iniciar(item) : null,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Iniciar atendimento'),
                    )
                  : FilledButton.icon(
                      key: ValueKey('finalizar-${item.id}'),
                      onPressed: _ocupado == null ? () => _finalizar(item) : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Finalizar atendimento'),
                    ),
            ),
        ],
      ),
    );
  }
}

class _DialogoFinalizarAtendimento extends StatefulWidget {
  const _DialogoFinalizarAtendimento({required this.agendamento});

  final AgendamentoClinix agendamento;

  @override
  State<_DialogoFinalizarAtendimento> createState() => _EstadoDialogoFinalizar();
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
            maxLength: 500,
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