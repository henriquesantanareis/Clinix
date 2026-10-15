import 'package:flutter/material.dart';

import 'agenda_clinix.dart';
import 'componentes_atendimento.dart';
import 'modelos_atendimento.dart';

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
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _profissional = TextEditingController();
  final _observacoes = TextEditingController();
  late DateTime _dataHora = widget.agenda.agora.add(const Duration(hours: 1));

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _profissional.dispose();
    _observacoes.dispose();
    super.dispose();
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

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    try {
      // O horário exibido tem precisão de minutos; não salvamos segundos ocultos.
      final dataHora = DateTime(
        _dataHora.year,
        _dataHora.month,
        _dataHora.day,
        _dataHora.hour,
        _dataHora.minute,
      );
      widget.agenda.agendar(
        paciente: PacienteClinix(nome: _nome.text, telefone: _telefone.text),
        profissional: _profissional.text,
        dataHora: dataHora,
        observacoes: _observacoes.text,
      );
      FocusScope.of(context).unfocus();
      _formKey.currentState!.reset();
      _nome.clear();
      _telefone.clear();
      _profissional.clear();
      _observacoes.clear();
      setState(
        () => _dataHora = widget.agenda.agora.add(const Duration(hours: 1)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento realizado nesta sessão.')),
      );
      widget.aoAgendar(dataHora);
    } catch (erro) {
      mostrarErroAtendimento(context, erro);
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
              TextFormField(
                key: const Key('nome-paciente'),
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nome do paciente',
                  counterText: '',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Informe o nome do paciente.'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _telefone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 32,
                decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('profissional'),
                controller: _profissional,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Profissional',
                  counterText: '',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Informe o profissional.'
                    : null,
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
              FilledButton.icon(
                key: const Key('salvar-agendamento'),
                onPressed: _salvar,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Realizar agendamento'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
