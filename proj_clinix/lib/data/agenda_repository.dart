import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/modelos_atendimento.dart';

// Único arquivo que fala com o Supabase. As telas não acessam o banco direto.
class AgendaRepository {
  AgendaRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // Colunas da consulta, com os nomes do banco. "pacientes(...)" e
  // "funcionarios(...)" trazem os nomes junto, sem uma segunda consulta.
  static const _colunas =
      'id, data_hora, observacoes_agendamento, status, chegada_em, iniciado_em, finalizado_em, observacoes_administrativas, pacientes(nome, telefone), funcionarios(nome)';

  // Agendamentos de um dia. O RLS já filtra: o profissional só recebe os dele.
  Future<List<AgendamentoClinix>> listarAgenda(DateTime dia) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fim = inicio.add(const Duration(days: 1));

    final linhas = await _client
        .from('agendamentos')
        .select(_colunas)
        .gte('data_hora', inicio.toUtc().toIso8601String())
        .lt('data_hora', fim.toUtc().toIso8601String())
        .order('data_hora');

    return linhas.map(_paraModelo).toList();
  }

  // Fila: quem está aguardando ou em atendimento, por ordem de chegada.
  Future<List<AgendamentoClinix>> listarFila() async {
    final linhas = await _client
        .from('agendamentos')
        .select(_colunas)
        .inFilter('status', ['aguardando', 'em_atendimento'])
        .order('chegada_em', ascending: true);

    return linhas.map(_paraModelo).toList();
  }

  Future<void> criarAgendamento({
    required String pacienteId,
    required String profissionalId,
    required DateTime dataHora,
    String observacoes = '',
  }) async {
    // criado_por é preenchido pelo banco com auth.uid()
    await _client.from('agendamentos').insert({
      'paciente_id': pacienteId,
      'profissional_id': profissionalId,
      'data_hora': dataHora.toUtc().toIso8601String(),
      'observacoes_agendamento': observacoes.trim(),
    });
  }

  Future<void> cadastrarPaciente({
    required String nome,
    required String cpf,
    String telefone = '',
    String cep = '',
    String logradouro = '',
    String numero = '',
    String bairro = '',
    String cidade = '',
    String uf = '',
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    await _client.from('pacientes').insert({
      'nome': nome.trim(),
      // CPF vazio vai como null: a restrição do banco aceita null, não texto vazio
      'cpf': cpfLimpo.isEmpty ? null : cpfLimpo,
      'telefone': telefone.trim(),
      'cep': cep.replaceAll(RegExp(r'\D'), ''),
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'uf': uf,
    });
  }

  // As ações passam pelas funções do banco, e não por update direto.
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

  // Converte a linha do banco no modelo que as telas já usam.
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