import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/agenda_repository.dart';
import '../models/modelos_atendimento.dart';
import '../widgets/componentes_atendimento.dart';

class PaginaListaPacientes extends StatefulWidget {
  const PaginaListaPacientes({super.key});

  @override
  State<PaginaListaPacientes> createState() => _EstadoListaPacientes();
}

class _EstadoListaPacientes extends State<PaginaListaPacientes> {
  final AgendaRepository _repositorio = AgendaRepository();
  final TextEditingController _busca = TextEditingController();
  List<PacienteClinix> _pacientes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final pacientes = await _repositorio.listarTodosPacientes();
      if (!mounted) return;
      setState(() => _pacientes = pacientes);
    } on PostgrestException catch (erro) {
      if (!mounted) return;
      final mensagem = switch (erro.code) {
        'PGRST202' =>
          'A consulta de pacientes ainda não foi instalada no Supabase. '
              'Aplique a migration 006_agendamento_profissional_busca_pacientes.sql.',
        '42501' =>
          'O perfil ou as permissões do banco não permitem listar pacientes. '
              'Confira as migrations 002 e 006.',
        _ => 'Não foi possível carregar os pacientes (${erro.code}).',
      };
      setState(() => _erro = mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erro = 'Não foi possível carregar os pacientes. Tente de novo.',
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _digitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

  String _formatarCpf(String cpf) {
    if (cpf.length != 11) return cpf.isEmpty ? 'Não informado' : cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.'
        '${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  @override
  Widget build(BuildContext context) {
    final termo = _busca.text.trim().toLowerCase();
    final termoDigitos = _digitos(termo);
    final pacientesFiltrados = _pacientes.where((paciente) {
      return paciente.nome.toLowerCase().contains(termo) ||
          (termoDigitos.isNotEmpty &&
              (_digitos(paciente.cpf).contains(termoDigitos) ||
                  _digitos(paciente.telefone).contains(termoDigitos)));
    }).toList();

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const CabecalhoAtendimento(
            titulo: 'Pacientes',
            descricao: 'Consulte os pacientes cadastrados e veja a próxima consulta futura.',
          ),
          TextField(
            controller: _busca,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Buscar paciente',
              hintText: 'Nome, CPF ou telefone',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busca.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        _busca.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (_carregando) const LinearProgressIndicator(),
          if (_erro != null) ...[
            EstadoVazioAtendimento(
              titulo: 'Não foi possível carregar os pacientes',
              descricao: _erro!,
              icone: Icons.error_outline,
              acao: TextButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ),
          ] else if (!_carregando && _pacientes.isEmpty)
            const EstadoVazioAtendimento(
              titulo: 'Nenhum paciente cadastrado',
              descricao: 'Os pacientes cadastrados aparecerão nesta lista.',
              icone: Icons.people_outline,
            )
          else if (!_carregando && pacientesFiltrados.isEmpty)
            const EstadoVazioAtendimento(
              titulo: 'Nenhum paciente encontrado',
              descricao: 'Tente buscar por outro nome, CPF ou telefone.',
              icone: Icons.search_off,
            ),
          if (_erro == null)
            for (final paciente in pacientesFiltrados)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFDCE3DD)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paciente.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Telefone: ${paciente.telefone.isEmpty ? 'Não informado' : paciente.telefone}',
                      ),
                      const SizedBox(height: 4),
                      Text('CPF: ${_formatarCpf(paciente.cpf)}'),
                      const SizedBox(height: 8),
                      if (paciente.proximaConsulta case final consulta?)
                        Text(
                          'Próxima consulta: ${formatarData(consulta)} às '
                          '${formatarHora(consulta)}',
                          style: const TextStyle(
                            color: Color(0xFF167A68),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        const Text(
                          'Sem consultas futuras agendadas.',
                          style: TextStyle(color: Color(0xFF687771)),
                        ),
                      if (paciente.profissionalProximaConsulta case final nome?)
                        Text('Profissional: $nome'),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
