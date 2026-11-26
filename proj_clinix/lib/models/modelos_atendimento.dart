enum PerfilClinix {
  operador('Operador'),
  administrativo('Administrativo'),
  profissional('Profissional'),
  gerente('Gerente');

  const PerfilClinix(this.rotulo);
  final String rotulo;

  bool get podeVerFila => true;
  bool get podeAgendar =>
      this == operador || this == profissional || this == gerente;
  bool get podeCheckIn => this == operador || this == gerente;
  bool get podeCancelar => this == operador || this == gerente;
  bool get podeAtender => this == profissional || this == gerente;
  bool get podeCadastrarPaciente => this == operador || this == gerente;
  bool get podeGerenciarFuncionarios => this == gerente;

  /// Recebe exclusivamente app_metadata, administrado pelo servidor.
  static PerfilClinix? deMetadados(Map<String, dynamic> metadados) {
    return switch (metadados['perfil']) {
      'operador' => operador,
      'administrativo' => administrativo,
      'profissional' => profissional,
      'gerente' => gerente,
      _ => null,
    };
  }
}

enum StatusAtendimento {
  agendado('agendado', 'Agendado'),
  aguardando('aguardando', 'Aguardando'),
  emAtendimento('em_atendimento', 'Em atendimento'),
  finalizado('finalizado', 'Finalizado'),
  cancelado('cancelado', 'Cancelado');

  const StatusAtendimento(this.valorBanco, this.rotulo);
  final String valorBanco;
  final String rotulo;
}

class PacienteClinix {
  const PacienteClinix({
    required this.nome,
    this.id = '',
    this.cpf = '',
    this.telefone = '',
    this.proximaConsulta,
    this.profissionalProximaConsulta,
  });

  final String id;
  final String nome;
  final String cpf;
  final String telefone;
  final DateTime? proximaConsulta;
  final String? profissionalProximaConsulta;
}

class SolicitacaoAcessoClinix {
  const SolicitacaoAcessoClinix({
    required this.usuarioId,
    required this.nome,
    required this.email,
    required this.criadaEm,
  });

  final String usuarioId;
  final String nome;
  final String email;
  final DateTime criadaEm;
}

class FuncionarioClinix {
  const FuncionarioClinix({
    required this.id,
    this.usuarioId,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.atende,
    required this.ativo,
  });

  final String id;
  final String? usuarioId;
  final String nome;
  final String email;
  final String cargo;
  final bool atende;
  final bool ativo;
}

class SolicitacaoRecuperacaoSenhaClinix {
  const SolicitacaoRecuperacaoSenhaClinix({
    required this.id,
    required this.usuarioId,
    required this.email,
    required this.criadaEm,
  });

  final String id;
  final String? usuarioId;
  final String email;
  final DateTime criadaEm;
}

class AgendamentoClinix {
  const AgendamentoClinix({
    required this.id,
    required this.paciente,
    required this.profissional,
    required this.dataHora,
    this.observacoes = '',
    this.status = StatusAtendimento.agendado,
    this.chegadaEm,
    this.iniciadoEm,
    this.finalizadoEm,
    this.anotacoes = '',
  });

  final String id;
  final PacienteClinix paciente;
  final String profissional;
  final DateTime dataHora;
  final String observacoes;
  final StatusAtendimento status;
  final DateTime? chegadaEm;
  final DateTime? iniciadoEm;
  final DateTime? finalizadoEm;
  final String anotacoes;

  AgendamentoClinix comStatus(
    StatusAtendimento novoStatus, {
    required DateTime instante,
    String anotacoes = '',
  }) {
    return AgendamentoClinix(
      id: id,
      paciente: paciente,
      profissional: profissional,
      dataHora: dataHora,
      observacoes: observacoes,
      status: novoStatus,
      chegadaEm: novoStatus == StatusAtendimento.aguardando
          ? instante
          : chegadaEm,
      iniciadoEm: novoStatus == StatusAtendimento.emAtendimento
          ? instante
          : iniciadoEm,
      finalizadoEm: novoStatus == StatusAtendimento.finalizado
          ? instante
          : finalizadoEm,
      anotacoes: novoStatus == StatusAtendimento.finalizado
          ? anotacoes
          : this.anotacoes,
    );
  }
}

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/${data.year}';

String formatarHora(DateTime data) =>
    '${data.hour.toString().padLeft(2, '0')}:'
    '${data.minute.toString().padLeft(2, '0')}';
