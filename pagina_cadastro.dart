import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'componentes_clinix.dart';

class PaginaCadastro extends StatefulWidget {
  const PaginaCadastro({super.key, required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  State<PaginaCadastro> createState() => _EstadoPaginaCadastro();
}

class _EstadoPaginaCadastro extends State<PaginaCadastro> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.supabaseConfigured) {
      _showMessage('Configure o Supabase para criar sua conta.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()},
      );
      if (!mounted) return;

      if (response.session != null) {
        Navigator.of(context).pop();
      } else {
        _showMessage('Conta criada. Confira seu e-mail para confirmar o cadastro.');
      }
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível criar a conta. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MarcaClinix(),
        backgroundColor: const Color(0xFFF4F6F1),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Criar sua conta',
                      style: TextStyle(
                        color: Color(0xFF183D37),
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Preencha seus dados para começar.',
                      style: TextStyle(
                        color: Color(0xFF687771),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const RotuloCampo('Nome completo'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        hintText: 'Seu nome',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const RotuloCampo('E-mail'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'SeuEmail@Exemplo.com',
                        prefixIcon: Icon(Icons.alternate_email, size: 20),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Informe seu e-mail.';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                          return 'Digite um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const RotuloCampo('Senha'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        hintText: 'Mínimo de 8 caracteres',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe sua senha.';
                        }
                        if (value.length < 8) {
                          return 'Use pelo menos 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const RotuloCampo('Confirme sua senha'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Digite a senha novamente',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme sua senha.';
                        }
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
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
                        ),
                        child: _isLoading
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Criar conta'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Já tenho uma conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
