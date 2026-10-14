import 'package:flutter/foundation.dart';

import 'modelos_atendimento.dart';

/// Estado das quatro telas durante a sessão. Não grava dados no Supabase.
class AgendaClinix extends ChangeNotifier {
  AgendaClinix({required this.perfil, DateTime Function()? relogio})
    : _relogio = relogio ?? DateTime.now;

  final PerfilClinix perfil;
  final DateTime Function() _relogio;
  final List<AgendamentoClinix> _agendamentos = [];
  int _proximoId = 1;

  DateTime get agora => _relogio();
  List<AgendamentoClinix> get agendamentos => List.unmodifiable(_agendamentos);

  AgendamentoClinix agendar({
    required PacienteClinix paciente,
    required String profissional,
    required DateTime dataHora,
    String observacoes = '',
  }) {
    final nome = _normalizar(paciente.nome);
    final responsavel = _normalizar(profissional);
    final horarioLocal = dataHora.toLocal();
    final horario = DateTime(
      horarioLocal.year,
      horarioLocal.month,
      horarioLocal.day,
      horarioLocal.hour,
      horarioLocal.minute,
    );
    if (nome.isEmpty || responsavel.isEmpty) {
      throw ArgumentError('Informe o paciente e o profissional.');
    }
    if (!horario.isAfter(agora)) {
      throw ArgumentError('Escolha uma data e um horário futuros.');
    }
    final conflito = _agendamentos.any(
      (item) =>
          item.profissional.toLowerCase() == responsavel.toLowerCase() &&
          item.dataHora.isAtSameMomentAs(horario),
    );
    if (conflito) {
      throw StateError(
        'Esse profissional já tem um agendamento nesse horário.',
      );
    }
    final item = AgendamentoClinix(
      id: '${_proximoId++}',
      paciente: PacienteClinix(nome: nome, telefone: paciente.telefone.trim()),
      profissional: responsavel,
      dataHora: horario,
      observacoes: observacoes.trim(),
    );
    _agendamentos.add(item);
    notifyListeners();
    return item;
  }

  void confirmarChegada(String id) {
    final indice = _indice(id);
    final item = _agendamentos[indice];
    if (!mesmoDia(item.dataHora, agora)) {
      throw StateError('Confirme a chegada no dia do agendamento.');
    }
    _mudarStatus(
      indice,
      de: StatusAtendimento.agendado,
      para: StatusAtendimento.aguardando,
    );
  }

  void iniciarAtendimento(String id) {
    _exigirPermissaoAtendimento();
    final indice = _indice(id);
    final item = _agendamentos[indice];
    final emCurso = _agendamentos.any(
      (outro) =>
          outro.id != item.id &&
          outro.status == StatusAtendimento.emAtendimento &&
          outro.profissional.toLowerCase() == item.profissional.toLowerCase(),
    );
    if (emCurso) {
      throw StateError(
        'Esse profissional já está em atendimento. Finalize-o antes de iniciar outro.',
      );
    }
    _mudarStatus(
      indice,
      de: StatusAtendimento.aguardando,
      para: StatusAtendimento.emAtendimento,
    );
  }

  void finalizarAtendimento(String id, {String anotacoes = ''}) {
    _exigirPermissaoAtendimento();
    _mudarStatus(
      _indice(id),
      de: StatusAtendimento.emAtendimento,
      para: StatusAtendimento.finalizado,
      anotacoes: anotacoes.trim(),
    );
  }

  void _mudarStatus(
    int indice, {
    required StatusAtendimento de,
    required StatusAtendimento para,
    String anotacoes = '',
  }) {
    final item = _agendamentos[indice];
    if (item.status != de) {
      throw StateError('O atendimento não está mais na etapa ${de.rotulo}.');
    }
    _agendamentos[indice] = item.comStatus(
      para,
      instante: agora,
      anotacoes: anotacoes,
    );
    notifyListeners();
  }

  void _exigirPermissaoAtendimento() {
    if (!perfil.podeAtender) {
      throw StateError('Seu perfil não permite realizar atendimentos.');
    }
  }

  int _indice(String id) {
    final indice = _agendamentos.indexWhere((item) => item.id == id);
    if (indice < 0) throw StateError('Agendamento não encontrado.');
    return indice;
  }

  String _normalizar(String valor) =>
      valor.trim().replaceAll(RegExp(r'\s+'), ' ');
}
