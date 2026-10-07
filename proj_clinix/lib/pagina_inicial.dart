import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'componentes_clinix.dart';

class PaginaInicial extends StatefulWidget {
  const PaginaInicial({super.key, required this.email});

  final String email;

  @override
  State<PaginaInicial> createState() => _EstadoPaginaInicial();
}

class _EstadoPaginaInicial extends State<PaginaInicial> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.email.isEmpty
        ? 'Bem-vindo(a)'
        : widget.email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');

    return Scaffold(
      appBar: AppBar(
        title: const MarcaClinix(),
        backgroundColor: const Color(0xFFF4F6F1),
        actions: [
          IconButton(
            onPressed: _isSigningOut ? null : _signOut,
            tooltip: 'Sair da conta',
            icon: _isSigningOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          constraints.maxWidth < 560 ? 24 : 36,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF183D37),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 24,
                          spacing: 24,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SUA ÁREA DE SAÚDE',
                                    style: TextStyle(
                                      color: Color(0xFFB9E2D0),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Olá, $displayName',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Bem-vindo(a) ao Clinix. Sua conta está conectada.',
                                    style: TextStyle(
                                      color: Color(0xFFD5E2DD),
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.health_and_safety_outlined,
                              color: Color(0xFFB9E2D0),
                              size: 56,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Conta conectada',
                        style: TextStyle(
                          color: Color(0xFF183D37),
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDCE3DD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alternate_email,
                              color: Color(0xFF167A68),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'E-mail',
                                    style: TextStyle(
                                      color: Color(0xFF687771),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.email,
                                    style: const TextStyle(
                                      color: Color(0xFF183D37),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF167A68),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Atividade recente',
                        style: TextStyle(
                          color: Color(0xFF183D37),
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDCE3DD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              color: Color(0xFF687771),
                              size: 24,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Ainda não há atividades para mostrar.',
                                style: TextStyle(
                                  color: Color(0xFF687771),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
