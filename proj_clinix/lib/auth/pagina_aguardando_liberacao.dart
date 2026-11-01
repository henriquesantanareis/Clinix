import 'package:flutter/material.dart';

import '../apis/supabase_api.dart';

// Tela para quem entrou, mas ainda não tem um perfil válido no app_metadata.
// Não libera nenhuma tela da clínica.
class PaginaAguardandoLiberacao extends StatelessWidget {
  const PaginaAguardandoLiberacao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Sua conta ainda não está liberada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Procure a administração da clínica para liberar seu acesso.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => SupabaseApi.signOut(),
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}