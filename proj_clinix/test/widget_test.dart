// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proj_clinix/pagina_inicial.dart';
import 'package:proj_clinix/main.dart';
import 'package:proj_clinix/pagina_cadastro.dart';

void main() {
  testWidgets('registration page validates required fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PaginaCadastro(supabaseConfigured: false),
      ),
    );

    expect(find.text('Criar sua conta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));

    await tester.ensureVisible(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(find.text('Confirme sua senha.'), findsOneWidget);
  });

  testWidgets('dashboard shows the authenticated account', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PaginaInicial(email: 'ana@clinix.com'),
      ),
    );

    expect(find.text('Olá, ana'), findsOneWidget);
    expect(find.text('ana@clinix.com'), findsOneWidget);
    expect(find.text('Atividade recente'), findsOneWidget);
  });

  testWidgets('login page validates required fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });
}
