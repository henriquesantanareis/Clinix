import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/agenda_repository.dart';
import '../models/agenda_clinix.dart';
import '../widgets/componentes_atendimento.dart';
import '../models/modelos_atendimento.dart';

class PaginaAgendamento extends StatefulWidget {
  const PaginaAgendamento({
    super.key,
    required this.agenda,
    required this.aoAgendar,
  });

  final AgendaClinix agenda;
  final ValueChanged<DateTime> aoAgendar;

  @override
  State<PaginaAgendamento> createState() => _EstadoAgendamento();
}

class _EstadoAgendamento extends State<PaginaAgendamento> {
  final _formKey = GlobalKey<FormState>();
  final _observacoes = TextEditingController();
  final AgendaRepository _repositorio = AgendaRepository();


  late DateTime _dataHora = widget.agenda.agora.add(const Duration(hours: 1));
  List<({String id, String nome})> _profissionais = [];
  List<({String id, String nome})> _pacientes = [];
  String? _pacienteId;
  String? _profissionalId;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
  }

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  // Carrega as listas de pacientes e profissionais do banco.
  Future<void> _carregarOpcoes() async {
    try {
      final pacientes = await _repositorio.listarPacientes();
      final profissionais = await _repositorio.listarProfissionais();
      if (!mounted) return;
      setState(() {
        _pacientes = pacientes;
        _profissionais = profissionais;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar pacientes e profissionais.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarData() async {
    final agora = widget.agenda.agora;
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final escolhida = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: _dataHora.isBefore(hoje) ? hoje : _dataHora,
      firstDate: hoje,
      lastDate: DateTime(agora.year + 5, 12, 31),
      helpText: 'Data do agendamento',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (escolhida != null && mounted) {
      setState(() {
        _dataHora = DateTime(
          escolhida.year,
          escolhida.month,
          escolhida.day,
          _dataHora.hour,
          _dataHora.minute,
        );
      });
    }
  }

  Future<void> _selecionarHora() async {
    final escolhida = await showTimePicker(
      context: context,
      useRootNavigator: false,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
      helpText: 'Horário do agendamento',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (escolhida != null && mounted) {
      setState(() {
        _dataHora = DateTime(
          _dataHora.year,
          _dataHora.month,
          _dataHora.day,
          escolhida.hour,
          escolhida.minute,
        );
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    // O horário exibido tem precisão de minutos; não salvamos segundos ocultos.
    final dataHora = DateTime(
      _dataHora.year,
      _dataHora.month,
      _dataHora.day,
      _dataHora.hour,
      _dataHora.minute,
    );
    if (!dataHora.isAfter(widget.agenda.agora)) {
      setState(() => _erro = 'Escolha um horário no futuro.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await _repositorio.criarAgendamento(
        pacienteId: _pacienteId!,
        profissionalId: _profissionalId!,
        dataHora: dataHora,
        observacoes: _observacoes.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento realizado.')),
      );
      setState(() {
        _pacienteId = null;
        _profissionalId = null;
        _observacoes.clear();
        _dataHora = widget.agenda.agora.add(const Duration(hours: 1));
      });
      widget.aoAgendar(dataHora);
    } on PostgrestException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.code == '23505'
            ? 'Este profissional já tem um agendamento nesse horário.'
            : 'Não foi possível salvar o agendamento. ${erro.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível salvar o agendamento. Tente de novo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CabecalhoAtendimento(
                titulo: 'Novo agendamento',
                descricao: 'Informe o paciente, o profissional e o horário desejado.',
              ),
              if (_carregando) const LinearProgressIndicator(),
              DropdownButtonFormField<String>(
                key: const Key('paciente'),
                initialValue: _pacienteId,
                decoration: InputDecoration(
                  labelText: 'Paciente',
                  helperText: !_carregando && _pacientes.isEmpty
                      ? 'Nenhum paciente cadastrado.'
                      : null,
                ),
                items: [
                  for (final p in _pacientes)
                    DropdownMenuItem(value: p.id, child: Text(p.nome)),
                ],
                onChanged: (v) => setState(() => _pacienteId = v),
                validator: (v) => v == null ? 'Escolha o paciente.' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                key: const Key('profissional'),
                initialValue: _profissionalId,
                decoration: InputDecoration(
                  labelText: 'Profissional',
                  helperText: !_carregando && _profissionais.isEmpty
                      ? 'Nenhum profissional disponível para atendimento.'
                      : null,
                ),
                items: [
                  for (final p in _profissionais)
                    DropdownMenuItem(value: p.id, child: Text(p.nome)),
                ],
                onChanged: (v) => setState(() => _profissionalId = v),
                validator: (v) => v == null ? 'Escolha o profissional.' : null,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _selecionarData,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('Data: ${formatarData(_dataHora)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _selecionarHora,
                    icon: const Icon(Icons.schedule),
                    label: Text('Horário: ${formatarHora(_dataHora)}'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _observacoes,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                key: const Key('salvar-agendamento'),
                onPressed: _salvando || _carregando ? null : _salvar,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(_salvando ? 'Salvando...' : 'Realizar agendamento'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
