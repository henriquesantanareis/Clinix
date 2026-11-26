import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../apis/supabase_api.dart';

class PaginaConta extends StatefulWidget {
  const PaginaConta({super.key, required this.email});

  final String email;

  @override
  State<PaginaConta> createState() => _EstadoPaginaConta();
}

class _EstadoPaginaConta extends State<PaginaConta> {
  bool _isSigningOut = false;
  bool _isChangingPassword = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await SupabaseApi.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível sair. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  Future<void> _changePersonalPassword() async {
    final senhaAtual = TextEditingController();
    final novaSenha = TextEditingController();
    final confirmarSenha = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var esconderSenhas = true;

    final credenciais = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, atualizarDialogo) => AlertDialog(
          title: const Text('Alterar minha senha'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: senhaAtual,
                      obscureText: esconderSenhas,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Senha atual',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => value?.isNotEmpty == true
                          ? null
                          : 'Informe sua senha atual.',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: novaSenha,
                      obscureText: esconderSenhas,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Nova senha',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      validator: (value) {
                        if ((value?.length ?? 0) < 8) {
                          return 'Use pelo menos 8 caracteres.';
                        }
                        if (value == senhaAtual.text) {
                          return 'Escolha uma senha diferente da atual.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmarSenha,
                      obscureText: esconderSenhas,
                      decoration: const InputDecoration(
                        labelText: 'Confirme a nova senha',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => value == novaSenha.text
                          ? null
                          : 'As senhas não coincidem.',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => atualizarDialogo(
                          () => esconderSenhas = !esconderSenhas,
                        ),
                        icon: Icon(
                          esconderSenhas
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        label: Text(
                          esconderSenhas ? 'Mostrar senhas' : 'Ocultar senhas',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext)
                      .pop((senhaAtual.text, novaSenha.text));
                }
              },
              child: const Text('Salvar nova senha'),
            ),
          ],
        ),
      ),
    );

    if (credenciais == null || !mounted) {
      senhaAtual.dispose();
      novaSenha.dispose();
      confirmarSenha.dispose();
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      final cliente = Supabase.instance.client;
      await cliente.auth.signInWithPassword(
        email: widget.email,
        password: credenciais.$1,
      );
      await cliente.auth.updateUser(UserAttributes(password: credenciais.$2));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua senha foi alterada com sucesso.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível alterar sua senha.')),
      );
    } finally {
      senhaAtual.dispose();
      novaSenha.dispose();
      confirmarSenha.dispose();
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Minha conta'),
      backgroundColor: const Color(0xFFF4F6F1),
      actions: [
        TextButton.icon(
          onPressed: _isSigningOut ? null : _signOut,
          icon: _isSigningOut
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Conta e segurança',
                  style: TextStyle(
                    color: Color(0xFF183D37),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gerencie seus dados de acesso ao Clinix.',
                  style: TextStyle(color: Color(0xFF687771), fontSize: 15),
                ),
                const SizedBox(height: 24),
                _CartaoConta(
                  icone: Icons.alternate_email,
                  titulo: 'E-mail',
                  descricao: widget.email,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDCE3DD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_outline, color: Color(0xFF167A68)),
                          SizedBox(width: 12),
                          Text(
                            'Senha',
                            style: TextStyle(
                              color: Color(0xFF183D37),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Altere sua senha confirmando a senha atual.',
                        style: TextStyle(color: Color(0xFF687771)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isChangingPassword
                            ? null
                            : _changePersonalPassword,
                        icon: _isChangingPassword
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lock_reset_outlined),
                        label: const Text('Alterar minha senha'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CartaoConta extends StatelessWidget {
  const _CartaoConta({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFDCE3DD)),
    ),
    child: Row(
      children: [
        Icon(icone, color: const Color(0xFF167A68)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: Color(0xFF687771), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                descricao,
                style: const TextStyle(
                  color: Color(0xFF183D37),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: Color(0xFF167A68), size: 20),
      ],
    ),
  );
}
