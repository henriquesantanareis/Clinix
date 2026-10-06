import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const _supabaseConfigured =
    _supabaseUrl != '' && _supabasePublishableKey != '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabaseConfigured) {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clinix',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF167A68),
          primary: const Color(0xFF167A68),
          surface: const Color(0xFFF4F6F1),
        ),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE3DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE3DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF167A68), width: 1.5),
          ),
        ),
      ),
      home: const LoginPage(supabaseConfigured: _supabaseConfigured),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      _showMessage('Não foi possível entrar. Verifique sua conexão e tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ensureSupabaseConfigured()) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      _showMessage(
        response.session == null
            ? 'Cadastro iniciado. Confira seu e-mail para confirmar a conta.'
            : 'Conta criada e sessão iniciada.',
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível criar a conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                      const Expanded(child: _BrandPanel()),
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
                            const _Wordmark(),
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
          const _FieldLabel('E-mail'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'SeuEmail@exemplo.com',
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
          const _FieldLabel('Senha'),
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
                onPressed: _isLoading ? null : _signUp,
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

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF183D37),
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Wordmark(light: true),
          const Spacer(),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF28564D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Color(0xFFB9E2D0),
              size: 31,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Seu cuidado,\nmais perto.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w600,
              height: 1.14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Acesse seus dados e mantenha sua jornada de saúde em dia.',
            style: TextStyle(
              color: Color(0xFFC5D5CF),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const Spacer(),
          const Text(
            'CLINIX  ·  SAÚDE COM CONFIANÇA',
            style: TextStyle(
              color: Color(0xFFB9CFC6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : const Color(0xFF183D37);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.add_box_rounded, color: Color(0xFFDF8968), size: 28),
        const SizedBox(width: 9),
        Text(
          'clinix',
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF28433B),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}