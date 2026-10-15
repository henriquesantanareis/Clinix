enum PerfilClinix {
  operador('Operador'),
  gerente('Gerente'),
  admin('Administrador');

  const PerfilClinix(this.rotulo);
  final String rotulo;

  bool get podeVerFila => this != operador;
  bool get podeAtender => this != operador;

  /// Recebe exclusivamente app_metadata, administrado pelo servidor.
  static PerfilClinix deMetadados(Map<String, dynamic> metadados) {
    return switch (metadados['perfil']) {
      'gerente' => gerente,
      'admin' => admin,
      _ => operador,
    };
  }
}

enum StatusAtendimento {
  agendado('Agendado'),
  aguardando('Aguardando'),
  emAtendimento('Em atendimento'),
  finalizado('Finalizado');

  const StatusAtendimento(this.rotulo);
  final String rotulo;
}

class PacienteClinix {
  const PacienteClinix({required this.nome, this.telefone = ''});

  final String nome;
  final String telefone;
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
