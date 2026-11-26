import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../apis/supabase_api.dart';
import '../data/agenda_repository.dart';
import 'pagina_login.dart';

class PaginaAguardandoLiberacao extends StatefulWidget {
  const PaginaAguardandoLiberacao({super.key});

  @override
  State<PaginaAguardandoLiberacao> createState() =>
      _EstadoAguardandoLiberacao();
}

class _EstadoAguardandoLiberacao extends State<PaginaAguardandoLiberacao> {
  final AgendaRepository _repositorio = AgendaRepository();
  String? _status;
  String? _erro;
  bool _checando = true;

  Future<void> _signOut() async {
    try {
      await SupabaseApi.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const PaginaLogin(supabaseConfigured: true),
        ),
        (_) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível sair. Tente novamente.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _atualizarStatus();
  }

  Future<void> _atualizarStatus() async {
    setState(() {
      _checando = true;
      _erro = null;
    });
    try {
      final status = await _repositorio.statusSolicitacaoAcessoAtual();
      if (!mounted) return;
      setState(() => _status = status);
      if (status == 'aprovado') {
        await Supabase.instance.client.auth.refreshSession();
      }
    } on AuthException {
      if (!mounted) return;
      setState(
        () => _erro = 'A liberação foi registrada, mas não foi possível atualizar a sessão. Saia e entre novamente.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erro = 'Não foi possível verificar o status. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _checando = false);
    }
  }

  String get _mensagem => switch (_status) {
    'aprovado' =>
      'Seu acesso foi aprovado. Atualize a sessão para entrar na clínica.',
    'rejeitado' => 'Sua solicitação de acesso não foi aprovada. Procure o gerente da clínica.',
    'pendente' =>
      'Sua conta está aguardando a aprovação do gerente da clínica.',
    _ => 'Sua conta ainda não está liberada. Procure o gerente da clínica.',
  };

  @override
  Widget build(BuildContext context) {
    final rejeitado = _status == 'rejeitado';
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rejeitado ? Icons.lock_outline : Icons.hourglass_empty,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  rejeitado
                      ? 'Acesso não aprovado'
                      : 'Aguardando liberação do gerente',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(_mensagem, textAlign: TextAlign.center),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erro!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _checando ? null : _atualizarStatus,
                  icon: _checando
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _checando ? 'Verificando...' : 'Verificar acesso',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _signOut, child: const Text('Sair')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
