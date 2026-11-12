import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/modelos_atendimento.dart';

class AgendaRepository {
  AgendaRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _colunas =
      'id, data_hora, observacoes_agendamento, status, chegada_em, iniciado_em, finalizado_em, observacoes_administrativas, pacientes(nome, telefone), funcionarios(nome)';

  (String, String) _intervaloDo(DateTime dia) {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fim = inicio.add(const Duration(days: 1));
    return (inicio.toUtc().toIso8601String(), fim.toUtc().toIso8601String());
  }

  Future<List<AgendamentoClinix>> listarAgenda(DateTime dia) async {
    final (inicio, fim) = _intervaloDo(dia);
    final linhas = await _client
        .from('agendamentos')
        .select(_colunas)
        .gte('data_hora', inicio)
        .lt('data_hora', fim)
        .order('data_hora');

    return linhas.map(_paraModelo).toList();
  }

  Future<List<AgendamentoClinix>> listarFila(DateTime dia) async {
    final (inicio, fim) = _intervaloDo(dia);
    final linhas = await _client
        .from('agendamentos')
        .select(_colunas)
        .inFilter('status', ['aguardando', 'em_atendimento'])
        .gte('data_hora', inicio)
        .lt('data_hora', fim)
        .order('chegada_em', ascending: true);

    return linhas.map(_paraModelo).toList();
  }

  Future<List<AgendamentoClinix>> listarFinalizados(DateTime dia) async {
    final (inicio, fim) = _intervaloDo(dia);
    final linhas = await _client
        .from('agendamentos')
        .select(_colunas)
        .eq('status', 'finalizado')
        .gte('finalizado_em', inicio)
        .lt('finalizado_em', fim)
        .order('finalizado_em', ascending: false);

    return linhas.map(_paraModelo).toList();
  }

  Future<void> criarAgendamento({
    required String pacienteId,
    required String profissionalId,
    required DateTime dataHora,
    String observacoes = '',
  }) async {
    await _client.from('agendamentos').insert({
      'paciente_id': pacienteId,
      'profissional_id': profissionalId,
      'data_hora': dataHora.toUtc().toIso8601String(),
      'observacoes_agendamento': observacoes.trim(),
    });
  }

  // Cadastra o paciente e devolve o id criado.
  // Campos vazios vão como null, para as restrições do banco funcionarem.
  Future<String> cadastrarPaciente({
    required String nome,
    required String cpf,
    required String telefone,
    String cep = '',
    String logradouro = '',
    String numero = '',
    String complemento = '',
    String bairro = '',
    String cidade = '',
    String uf = '',
  }) async {
    String apenasDigitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');
    String? vazioParaNull(String valor) {
      final t = valor.trim();
      return t.isEmpty ? null : t;
    }

    final cepLimpo = apenasDigitos(cep);
    final linha = await _client
        .from('pacientes')
        .insert({
          'nome': nome.trim(),
          'cpf': apenasDigitos(cpf),
          'telefone': apenasDigitos(telefone),
          'cep': cepLimpo.isEmpty ? null : cepLimpo,
          'logradouro': vazioParaNull(logradouro),
          'numero': vazioParaNull(numero),
          'complemento': vazioParaNull(complemento),
          'bairro': vazioParaNull(bairro),
          'cidade': vazioParaNull(cidade),
          'uf': vazioParaNull(uf)?.toUpperCase(),
        })
        .select('id')
        .single();
    return linha['id'] as String;
  }

  Future<void> registrarChegada(String id) async {
    await _client.rpc('registrar_chegada', params: {'p_agendamento_id': id});
  }

  Future<void> iniciarAtendimento(String id) async {
    await _client.rpc('iniciar_atendimento', params: {'p_agendamento_id': id});
  }

  Future<void> encerrarAtendimento(String id, String anotacoes) async {
    await _client.rpc(
      'encerrar_atendimento',
      params: {'p_agendamento_id': id, 'p_anotacoes': anotacoes.trim()},
    );
  }

  Future<void> cancelarAgendamento(String id) async {
    await _client.rpc('cancelar_agendamento', params: {'p_agendamento_id': id});
  }

  // Profissionais que atendem, para o campo de profissional do agendamento.
  Future<List<({String id, String nome})>> listarProfissionais() async {
    final linhas = await _client
        .from('funcionarios')
        .select('id, nome')
        .eq('atende', true)
        .eq('ativo', true)
        .order('nome');
    return linhas
        .map((l) => (id: l['id'] as String, nome: l['nome'] as String))
        .toList();
  }

  Future<({String id, String nome})?> profissionalAtual() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    final linha = await _client
        .from('funcionarios')
        .select('id, nome')
        .eq('user_id', usuario.id)
        .eq('ativo', true)
        .eq('atende', true)
        .maybeSingle();
    if (linha == null) return null;
    return (id: linha['id'] as String, nome: linha['nome'] as String);
  }

  Future<List<({String id, String nome})>> buscarPacientesParaAgendamento(
    String busca,
  ) async {
    final linhas = await _client.rpc(
      'buscar_pacientes_para_agendamento',
      params: {'p_busca': busca.trim()},
    );
    return linhas
        .map(
          (linha) => (id: linha['id'] as String, nome: linha['nome'] as String),
        )
        .toList();
  }

  Future<List<PacienteClinix>> listarTodosPacientes() async {
    final linhas = await _client.rpc('listar_pacientes_com_proxima_consulta');
    return linhas
        .map(
          (linha) => PacienteClinix(
            id: linha['paciente_id'] as String,
            nome: linha['nome'] as String,
            cpf: (linha['cpf'] ?? '') as String,
            telefone: (linha['telefone'] ?? '') as String,
            proximaConsulta: _data(linha['proxima_consulta']),
            profissionalProximaConsulta:
                linha['profissional_proxima_consulta'] as String?,
          ),
        )
        .toList();
  }

  Future<String?> statusSolicitacaoAcessoAtual() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    final linha = await _client
        .from('solicitacoes_acesso')
        .select('status')
        .eq('usuario_id', usuario.id)
        .maybeSingle();
    return linha?['status'] as String?;
  }

  Future<List<SolicitacaoAcessoClinix>> listarSolicitacoesAcesso() async {
    final linhas = await _client
        .from('solicitacoes_acesso')
        .select('usuario_id, nome, email, criada_em')
        .eq('status', 'pendente')
        .order('criada_em');
    return linhas
        .map(
          (linha) => SolicitacaoAcessoClinix(
            usuarioId: linha['usuario_id'] as String,
            nome: linha['nome'] as String,
            email: linha['email'] as String,
            criadaEm: DateTime.parse(linha['criada_em'] as String).toLocal(),
          ),
        )
        .toList();
  }

  Future<void> aprovarSolicitacaoAcesso(String usuarioId, String perfil) async {
    await _client.rpc(
      'aprovar_solicitacao_acesso',
      params: {'p_usuario_id': usuarioId, 'p_perfil': perfil},
    );
  }

  Future<void> rejeitarSolicitacaoAcesso(String usuarioId) async {
    await _client.rpc(
      'rejeitar_solicitacao_acesso',
      params: {'p_usuario_id': usuarioId},
    );
  }

  Future<List<FuncionarioClinix>> listarFuncionarios() async {
    final linhas = await _client
        .from('funcionarios')
        .select('id, nome, email, cargo, atende, ativo')
        .order('nome');
    return linhas
        .map(
          (linha) => FuncionarioClinix(
            id: linha['id'] as String,
            nome: linha['nome'] as String,
            email: (linha['email'] ?? '') as String,
            cargo: linha['cargo'] as String,
            atende: linha['atende'] as bool,
            ativo: linha['ativo'] as bool,
          ),
        )
        .toList();
  }

  Future<void> cadastrarFuncionario({
    required String nome,
    String email = '',
    String cargo = '',
    required bool atende,
  }) async {
    await _client.rpc(
      'cadastrar_funcionario',
      params: {
        'p_nome': nome.trim(),
        'p_email': email.trim(),
        'p_cargo': cargo.trim(),
        'p_atende': atende,
      },
    );
  }

  AgendamentoClinix _paraModelo(Map<String, dynamic> linha) {
    final paciente = linha['pacientes'] as Map<String, dynamic>;
    final funcionario = linha['funcionarios'] as Map<String, dynamic>;

    return AgendamentoClinix(
      id: linha['id'] as String,
      paciente: PacienteClinix(
        nome: paciente['nome'] as String,
        telefone: (paciente['telefone'] ?? '') as String,
      ),
      profissional: funcionario['nome'] as String,
      dataHora: DateTime.parse(linha['data_hora'] as String).toLocal(),
      observacoes: (linha['observacoes_agendamento'] ?? '') as String,
      status: StatusAtendimento.values.firstWhere(
        (s) => s.valorBanco == linha['status'],
      ),
      chegadaEm: _data(linha['chegada_em']),
      iniciadoEm: _data(linha['iniciado_em']),
      finalizadoEm: _data(linha['finalizado_em']),
      anotacoes: (linha['observacoes_administrativas'] ?? '') as String,
    );
  }

  DateTime? _data(Object? valor) =>
      valor == null ? null : DateTime.parse(valor as String).toLocal();
}
