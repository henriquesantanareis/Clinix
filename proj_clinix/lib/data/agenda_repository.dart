import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/modelos_atendimento.dart';

class AgendaRepository {
  AgendaRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

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

  Future<String> cadastrarPaciente({
    required String nome,
    String cpf = '',
    String telefone = '',
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    final linha = await _client
        .from('pacientes')
        .insert({
          'nome': nome.trim(),
          'cpf': cpfLimpo.isEmpty ? null : cpfLimpo,
          'telefone': telefone.trim(),
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
    await _client.rpc('encerrar_atendimento', params: {
      'p_agendamento_id': id,
      'p_anotacoes': anotacoes.trim(),
    });
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

  // Pacientes cadastrados, para escolher no agendamento.
  Future<List<({String id, String nome})>> listarPacientes() async {
    final linhas = await _client.from('pacientes').select('id, nome').order('nome');
    return linhas
        .map((l) => (id: l['id'] as String, nome: l['nome'] as String))
        .toList();
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

  DateTime? _data(Object? valor) => valor == null ? null : DateTime.parse(valor as String).toLocal();
}