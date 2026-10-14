import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'componentes_clinix.dart';
import 'pagina_cadastro.dart';

class PaginaLogin extends StatefulWidget {
  const PaginaLogin({super.key, required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  State<PaginaLogin> createState() => _EstadoPaginaLogin();
}

class _EstadoPaginaLogin extends State<PaginaLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ensureSupabaseConfigured()) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      _showMessage('Login realizado. Sua sessão está ativa.');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Não foi possível entrar. Verifique sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaginaCadastro(
          supabaseConfigured: widget.supabaseConfigured,
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Informe um e-mail válido para recuperar a senha.');
      return;
    }
    if (!_ensureSupabaseConfigured()) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showMessage('Se a conta existir, você receberá um link de recuperação.');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível enviar o link. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _ensureSupabaseConfigured() {
    if (widget.supabaseConfigured) return true;
    _showMessage('Configure a URL e a chave pública do Supabase para continuar.');
    return false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final content = isWide
                ? Row(
                    children: [
                      const Expanded(child: PainelMarcaClinix()),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 40,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 390),
                              child: _buildForm(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const MarcaClinix(),
                            const SizedBox(height: 48),
                            _buildForm(),
                          ],
                        ),
                      ),
                    ),
                  );

            if (!isWide) return content;
            return Padding(
              padding: const EdgeInsets.all(18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Acesse sua conta',
            style: TextStyle(
              color: Color(0xFF183D37),
              fontSize: 29,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Entre para acompanhar seu cuidado de onde estiver.',
            style: TextStyle(
              color: Color(0xFF687771),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const RotuloCampo('E-mail'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'SeuEmail@Exemplo.com',
              prefixIcon: Icon(Icons.alternate_email, size: 20),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Informe seu e-mail.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Digite um e-mail válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const RotuloCampo('Senha'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Mínimo de 8 caracteres',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe sua senha.';
              if (value.length < 8) return 'Use pelo menos 8 caracteres.';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _sendPasswordReset,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF167A68),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Esqueci minha senha'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF167A68),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Entrar'),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Ainda não tem conta?',
                style: TextStyle(color: Color(0xFF687771)),
              ),
              TextButton(
                onPressed: _isLoading ? null : _openRegistration,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF167A68),
                  padding: const EdgeInsets.only(left: 7),
                ),
                child: const Text('Criar conta'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF87938D),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
