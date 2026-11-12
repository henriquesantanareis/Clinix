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
  final _buscaPaciente = TextEditingController();
  final AgendaRepository _repositorio = AgendaRepository();

  late DateTime _dataHora = widget.agenda.agora.add(const Duration(hours: 1));
  List<({String id, String nome})> _profissionais = [];
  List<({String id, String nome})> _resultadosPacientes = [];
  String? _pacienteId;
  String? _pacienteNome;
  String? _profissionalId;
  String? _profissionalNome;
  bool _carregando = true;
  bool _buscandoPacientes = false;
  bool _salvando = false;
  String? _erro;
  String? _erroBuscaPaciente;
  int _versaoBuscaPaciente = 0;

  bool get _profissionalLogado =>
      widget.agenda.perfil == PerfilClinix.profissional;

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
  }

  @override
  void dispose() {
    _observacoes.dispose();
    _buscaPaciente.dispose();
    super.dispose();
  }

  Future<void> _carregarOpcoes() async {
    try {
      final profissional = _profissionalLogado
          ? await _repositorio.profissionalAtual()
          : null;
      final profissionais = _profissionalLogado
          ? <({String id, String nome})>[]
          : await _repositorio.listarProfissionais();
      if (!mounted) return;
      setState(() {
        _profissionais = profissionais;
        if (_profissionalLogado) {
          _profissionalId = profissional?.id;
          _profissionalNome = profissional?.nome;
          if (profissional == null) {
            _erro = 'Seu perfil não está vinculado a um funcionário ativo que realiza atendimentos. Procure o gerente.';
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erro = 'Não foi possível carregar pacientes e profissionais.',
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _buscarPacientes(String valor) async {
    final busca = valor.trim();
    final versao = ++_versaoBuscaPaciente;
    setState(() {
      _pacienteId = null;
      _pacienteNome = null;
      _erroBuscaPaciente = null;
      _resultadosPacientes = [];
      _buscandoPacientes = busca.length >= 2;
    });
    if (busca.length < 2) return;

    try {
      final resultados = await _repositorio.buscarPacientesParaAgendamento(
        busca,
      );
      if (!mounted || versao != _versaoBuscaPaciente) return;
      setState(() => _resultadosPacientes = resultados);
    } on PostgrestException catch (erro) {
      if (!mounted || versao != _versaoBuscaPaciente) return;
      setState(
        () => _erroBuscaPaciente = erro.code == 'PGRST202'
            ? 'A busca de pacientes ainda não foi instalada no Supabase. '
                  'Aplique a migration 006_agendamento_profissional_busca_pacientes.sql.'
            : 'Não foi possível pesquisar pacientes (${erro.code}).',
      );
    } catch (_) {
      if (!mounted || versao != _versaoBuscaPaciente) return;
      setState(
        () => _erroBuscaPaciente =
            'Não foi possível pesquisar pacientes. Tente novamente.',
      );
    } finally {
      if (mounted && versao == _versaoBuscaPaciente) {
        setState(() => _buscandoPacientes = false);
      }
    }
  }

  void _selecionarPaciente(({String id, String nome}) paciente) {
    _versaoBuscaPaciente++;
    setState(() {
      _pacienteId = paciente.id;
      _pacienteNome = paciente.nome;
      _buscaPaciente.text = paciente.nome;
      _resultadosPacientes = [];
      _buscandoPacientes = false;
      _erroBuscaPaciente = null;
    });
    FocusScope.of(context).unfocus();
    _formKey.currentState?.validate();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agendamento realizado.')));
      setState(() {
        _pacienteId = null;
        _pacienteNome = null;
        _buscaPaciente.clear();
        _resultadosPacientes = [];
        if (!_profissionalLogado) {
          _profissionalId = null;
        }
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
      setState(
        () => _erro = 'Não foi possível salvar o agendamento. Tente de novo.',
      );
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
                descricao:
                    'Informe o paciente, o profissional e o horário desejado.',
              ),
              if (_carregando) const LinearProgressIndicator(),
              TextFormField(
                key: const Key('paciente'),
                controller: _buscaPaciente,
                onChanged: _buscarPacientes,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Buscar paciente',
                  hintText: 'Digite pelo menos 2 letras do nome',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _buscandoPacientes
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                validator: (_) => _pacienteId == null
                    ? 'Selecione um paciente da busca.'
                    : null,
              ),
              if (_erroBuscaPaciente != null) ...[
                const SizedBox(height: 8),
                Text(
                  _erroBuscaPaciente!,
                  style: const TextStyle(color: Colors.red),
                ),
              ] else if (_resultadosPacientes.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      for (final paciente in _resultadosPacientes)
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(paciente.nome),
                          onTap: () => _selecionarPaciente(paciente),
                        ),
                    ],
                  ),
                )
              else if (!_buscandoPacientes &&
                  _buscaPaciente.text.trim().length >= 2 &&
                  _pacienteId == null &&
                  _erroBuscaPaciente == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Nenhum paciente encontrado.'),
                )
              else if (_pacienteNome != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Paciente selecionado: $_pacienteNome'),
                ),
              const SizedBox(height: 20),
              if (_profissionalLogado)
                TextFormField(
                  key: const Key('profissional-logado'),
                  initialValue: _profissionalNome ?? '',
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Profissional'),
                )
              else
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
                  validator: (v) =>
                      v == null ? 'Escolha o profissional.' : null,
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
                onPressed: _salvando || _carregando || _profissionalId == null
                    ? null
                    : _salvar,
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
