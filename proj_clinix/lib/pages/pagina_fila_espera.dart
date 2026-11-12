import 'package:flutter/material.dart';

import '../data/agenda_repository.dart';
import '../models/agenda_clinix.dart';
import '../models/modelos_atendimento.dart';
import '../widgets/componentes_atendimento.dart';

class PaginaFilaEspera extends StatefulWidget {
  const PaginaFilaEspera({super.key, required this.agenda});

  final AgendaClinix agenda;

  @override
  State<PaginaFilaEspera> createState() => _EstadoFilaEspera();
}

class _EstadoFilaEspera extends State<PaginaFilaEspera> {
  final AgendaRepository _repositorio = AgendaRepository();

  StatusAtendimento _filtro = StatusAtendimento.aguardando;
  List<AgendamentoClinix> _todos = [];
  bool _carregando = false;
  String? _cancelandoId;
  String? _erro;

  @override
  void initState() {
    super.initState();
    if (widget.agenda.perfil.podeVerFila) _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final hoje = widget.agenda.agora;
      final fila = await _repositorio.listarFila(hoje);
      final finalizados = await _repositorio.listarFinalizados(hoje);
      if (!mounted) return;
      setState(() => _todos = [...fila, ...finalizados]);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erro = 'Não foi possível carregar a fila. Tente de novo.',
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cancelarAgendamento(AgendamentoClinix item) async {
    if (!widget.agenda.perfil.podeCancelar ||
        !await confirmarCancelamentoAgendamento(context, item)) {
      return;
    }

    setState(() => _cancelandoId = item.id);
    try {
      await _repositorio.cancelarAgendamento(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agendamento cancelado.')));
      await _carregar();
    } catch (erro) {
      if (!mounted) return;
      mostrarErroAtendimento(context, erro);
    } finally {
      if (mounted) setState(() => _cancelandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.agenda.perfil.podeVerFila) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: EstadoVazioAtendimento(
          titulo: 'Acesso restrito',
          descricao: 'Seu perfil não acessa a fila de espera.',
          icone: Icons.lock_outline,
        ),
      );
    }

    final itens = _todos.where((item) => item.status == _filtro).toList()
      ..sort((a, b) {
        if (_filtro == StatusAtendimento.finalizado) {
          return (b.finalizadoEm ?? DateTime(0)).compareTo(
            a.finalizadoEm ?? DateTime(0),
          );
        }
        return (a.chegadaEm ?? a.dataHora).compareTo(b.chegadaEm ?? b.dataHora);
      });

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
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
                    '${status.rotulo} (${_todos.where((item) => item.status == status).length})',
                  ),
                  selected: _filtro == status,
                  onSelected: (_) => setState(() => _filtro = status),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_erro != null) ...[
            Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
          ],
          if (!_carregando && _erro == null && itens.isEmpty)
            EstadoVazioAtendimento(
              titulo: 'Nenhum paciente nesta etapa',
              descricao:
                  'Os pacientes aparecerão aqui quando estiverem na etapa ${_filtro.rotulo.toLowerCase()}.',
              icone: Icons.people_outline,
            ),
          for (final item in itens)
            CartaoAgendamento(
              agendamento: item,
              mostrarAnotacoes: true,
              acao:
                  item.status == StatusAtendimento.aguardando &&
                      widget.agenda.perfil.podeCancelar
                  ? TextButton.icon(
                      key: ValueKey('cancelar-${item.id}'),
                      icon: _cancelandoId == item.id
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.event_busy_outlined, size: 18),
                      label: Text(
                        _cancelandoId == item.id ? 'Cancelando...' : 'Cancelar',
                      ),
                      onPressed: _cancelandoId == item.id
                          ? null
                          : () => _cancelarAgendamento(item),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
