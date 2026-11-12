import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/agenda_repository.dart';
import '../models/modelos_atendimento.dart';
import '../widgets/componentes_atendimento.dart';

enum _SecaoGestao { acessos, funcionarios }

class PaginaGestaoClinica extends StatefulWidget {
  const PaginaGestaoClinica({super.key});

  @override
  State<PaginaGestaoClinica> createState() => _EstadoGestaoClinica();
}

class _EstadoGestaoClinica extends State<PaginaGestaoClinica> {
  _SecaoGestao _secao = _SecaoGestao.acessos;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: CabecalhoAtendimento(
          titulo: 'Acessos e equipe',
          descricao: 'Confira quem pediu acesso ao sistema e gerencie os funcionários.',
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SegmentedButton<_SecaoGestao>(
          segments: const [
            ButtonSegment(
              value: _SecaoGestao.acessos,
              icon: Icon(Icons.verified_user_outlined),
              label: Text('Solicitações'),
            ),
            ButtonSegment(
              value: _SecaoGestao.funcionarios,
              icon: Icon(Icons.badge_outlined),
              label: Text('Funcionários'),
            ),
          ],
          selected: {_secao},
          onSelectionChanged: (value) => setState(() => _secao = value.first),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: switch (_secao) {
          _SecaoGestao.acessos => const _SolicitacoesAcesso(),
          _SecaoGestao.funcionarios => const _CadastroFuncionarios(),
        },
      ),
    ],
  );
}

class _SolicitacoesAcesso extends StatefulWidget {
  const _SolicitacoesAcesso();

  @override
  State<_SolicitacoesAcesso> createState() => _EstadoSolicitacoesAcesso();
}

class _EstadoSolicitacoesAcesso extends State<_SolicitacoesAcesso> {
  final AgendaRepository _repositorio = AgendaRepository();
  List<SolicitacaoAcessoClinix> _solicitacoes = [];
  bool _carregando = true;
  String? _erro;
  String? _processandoId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final solicitacoes = await _repositorio.listarSolicitacoesAcesso();
      if (!mounted) return;
      setState(() => _solicitacoes = solicitacoes);
    } on PostgrestException catch (erro) {
      if (!mounted) return;
      setState(
        () => _erro = erro.code == 'PGRST205'
            ? 'A lista de solicitações ainda não foi instalada no Supabase. '
                  'Aplique a migration 005_liberacao_gerente_funcionarios.sql.'
            : 'Não foi possível carregar as solicitações (${erro.code}).',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar as solicitações.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<String?> _escolherPerfil(SolicitacaoAcessoClinix solicitacao) async {
    var perfil = 'operador';
    return showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizarDialogo) => AlertDialog(
          title: const Text('Aprovar acesso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Escolha o perfil de ${solicitacao.nome}:'),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: perfil,
                onChanged: (valor) {
                  if (valor != null) atualizarDialogo(() => perfil = valor);
                },
                child: Column(
                  children: [
                    for (final (valor, rotulo) in [
                      ('operador', 'Operador'),
                      ('administrativo', 'Administrativo'),
                      ('profissional', 'Profissional'),
                    ])
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(rotulo),
                        value: valor,
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(perfil),
              child: const Text('Aprovar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aprovar(SolicitacaoAcessoClinix solicitacao) async {
    final perfil = await _escolherPerfil(solicitacao);
    if (perfil == null || !mounted) return;
    setState(() => _processandoId = solicitacao.usuarioId);
    try {
      await _repositorio.aprovarSolicitacaoAcesso(
        solicitacao.usuarioId,
        perfil,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Acesso de ${solicitacao.nome} liberado.')),
      );
      await _carregar();
    } catch (erro) {
      if (!mounted) return;
      mostrarErroAtendimento(context, erro);
    } finally {
      if (mounted) setState(() => _processandoId = null);
    }
  }

  Future<void> _rejeitar(SolicitacaoAcessoClinix solicitacao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar solicitação?'),
        content: Text(
          'A conta de ${solicitacao.nome} não terá acesso à clínica.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Manter pendente'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _processandoId = solicitacao.usuarioId);
    try {
      await _repositorio.rejeitarSolicitacaoAcesso(solicitacao.usuarioId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitação de ${solicitacao.nome} rejeitada.'),
        ),
      );
      await _carregar();
    } catch (erro) {
      if (!mounted) return;
      mostrarErroAtendimento(context, erro);
    } finally {
      if (mounted) setState(() => _processandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _carregar,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        if (_carregando) const LinearProgressIndicator(),
        if (_erro != null)
          EstadoVazioAtendimento(
            titulo: 'Erro ao carregar acessos',
            descricao: _erro!,
            icone: Icons.error_outline,
            acao: TextButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          )
        else if (!_carregando && _solicitacoes.isEmpty)
          const EstadoVazioAtendimento(
            titulo: 'Nenhuma solicitação pendente',
            descricao: 'Novas contas cadastradas pelo site aparecerão aqui.',
            icone: Icons.verified_user_outlined,
          ),
        if (_erro == null)
          for (final solicitacao in _solicitacoes)
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
                      solicitacao.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(solicitacao.email),
                    const SizedBox(height: 8),
                    Text(
                      'Solicitado em ${formatarData(solicitacao.criadaEm)} '
                      'às ${formatarHora(solicitacao.criadaEm)}',
                      style: const TextStyle(color: Color(0xFF687771)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _processandoId == null
                              ? () => _aprovar(solicitacao)
                              : null,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Aprovar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _processandoId == null
                              ? () => _rejeitar(solicitacao)
                              : null,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Rejeitar'),
                        ),
                      ],
                    ),
                    if (_processandoId == solicitacao.usuarioId) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
      ],
    ),
  );
}

class _CadastroFuncionarios extends StatefulWidget {
  const _CadastroFuncionarios();

  @override
  State<_CadastroFuncionarios> createState() => _EstadoCadastroFuncionarios();
}

class _EstadoCadastroFuncionarios extends State<_CadastroFuncionarios> {
  final AgendaRepository _repositorio = AgendaRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _cargo = TextEditingController();
  List<FuncionarioClinix> _funcionarios = [];
  bool _atende = false;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _cargo.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final funcionarios = await _repositorio.listarFuncionarios();
      if (!mounted) return;
      setState(() => _funcionarios = funcionarios);
    } on PostgrestException catch (erro) {
      if (!mounted) return;
      final mensagem = switch (erro.code) {
        'PGRST204' =>
          'O banco não tem os campos de funcionários da migration 005. '
              'Aplique as migrations na ordem indicada no README.',
        '42501' =>
          'O banco recusou o acesso aos funcionários. Confira se as '
              'políticas da migration 002 e a migration 005 foram aplicadas.',
        _ => 'Não foi possível carregar os funcionários (${erro.code}).',
      };
      setState(() => _erro = mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar os funcionários.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await _repositorio.cadastrarFuncionario(
        nome: _nome.text,
        email: _email.text,
        cargo: _cargo.text,
        atende: _atende,
      );
      if (!mounted) return;
      _nome.clear();
      _email.clear();
      _cargo.clear();
      setState(() => _atende = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Funcionário cadastrado.')));
      await _carregar();
    } on PostgrestException catch (erro) {
      if (!mounted) return;
      final mensagem = switch (erro.code) {
        'PGRST202' =>
          'O cadastro de funcionários ainda não foi instalado no Supabase. '
              'Aplique a migration 005_liberacao_gerente_funcionarios.sql.',
        '42501' =>
          'Sua conta não tem permissão para cadastrar funcionários. '
              'Entre com o perfil de gerente e confirme a migration 005.',
        '23505' =>
          'Já existe um funcionário vinculado a esta conta ou a este e-mail.',
        _ => 'Não foi possível cadastrar o funcionário (${erro.code}).',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (erro) {
      if (!mounted) return;
      mostrarErroAtendimento(context, erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _carregar,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nome completo *',
                  counterText: '',
                ),
                validator: (valor) => valor?.trim().isNotEmpty == true
                    ? null
                    : 'Informe o nome do funcionário.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail para vincular acesso (opcional)',
                  helperText: 'Se a pessoa já tiver conta ou se cadastrar com este e-mail, o vínculo será feito automaticamente.',
                ),
                validator: (valor) {
                  final email = valor?.trim() ?? '';
                  if (email.isEmpty) return null;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : 'Informe um e-mail válido.';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cargo,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Cargo (opcional)',
                  counterText: '',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Realiza atendimentos'),
                value: _atende,
                onChanged: (valor) => setState(() => _atende = valor),
              ),
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_outlined),
                label: Text(
                  _salvando ? 'Salvando...' : 'Cadastrar funcionário',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Funcionários cadastrados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (_carregando) const LinearProgressIndicator(),
        if (_erro != null)
          Text(_erro!, style: const TextStyle(color: Colors.red)),
        if (!_carregando && _erro == null && _funcionarios.isEmpty)
          const Text('Ainda não há funcionários cadastrados.'),
        for (final funcionario in _funcionarios)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFDCE3DD)),
            ),
            child: ListTile(
              leading: Icon(
                funcionario.atende
                    ? Icons.medical_services_outlined
                    : Icons.badge_outlined,
              ),
              title: Text(funcionario.nome),
              subtitle: Text(
                [
                  if (funcionario.cargo.isNotEmpty) funcionario.cargo,
                  if (funcionario.email.isNotEmpty) funcionario.email,
                  funcionario.atende ? 'Atende pacientes' : 'Administrativo',
                ].join(' · '),
              ),
              trailing: Icon(
                funcionario.ativo ? Icons.check_circle_outline : Icons.block,
                color: funcionario.ativo ? Colors.teal : Colors.grey,
                semanticLabel: funcionario.ativo ? 'Ativo' : 'Inativo',
              ),
            ),
          ),
      ],
    ),
  );
}
