import 'package:flutter_test/flutter_test.dart';
import 'package:proj_clinix/models/modelos_atendimento.dart';

void main() {
  group('PerfilClinix', () {
    test('recepção agenda, faz check-in e cancela, mas não atende', () {
      expect(PerfilClinix.operador.podeAgendar, isTrue);
      expect(PerfilClinix.operador.podeCheckIn, isTrue);
      expect(PerfilClinix.operador.podeCancelar, isTrue);
      expect(PerfilClinix.operador.podeAtender, isFalse);
    });

    test('profissional atende, mas não agenda nem faz check-in', () {
      expect(PerfilClinix.profissional.podeAtender, isTrue);
      expect(PerfilClinix.profissional.podeAgendar, isFalse);
      expect(PerfilClinix.profissional.podeCheckIn, isFalse);
    });

    test('administrativo só vê a fila, sem agir', () {
      expect(PerfilClinix.administrativo.podeVerFila, isTrue);
      expect(PerfilClinix.administrativo.podeAgendar, isFalse);
      expect(PerfilClinix.administrativo.podeCheckIn, isFalse);
      expect(PerfilClinix.administrativo.podeCancelar, isFalse);
      expect(PerfilClinix.administrativo.podeAtender, isFalse);
    });

    test('gerente tem as permissões de operação e de atendimento', () {
      expect(PerfilClinix.gerente.podeAgendar, isTrue);
      expect(PerfilClinix.gerente.podeAtender, isTrue);
      expect(PerfilClinix.gerente.podeGerenciarFuncionarios, isTrue);
    });

    test('só o gerente gerencia funcionários', () {
      for (final perfil in PerfilClinix.values) {
        expect(perfil.podeGerenciarFuncionarios, perfil == PerfilClinix.gerente);
      }
    });

    test('perfil reconhecido é lido do app_metadata', () {
      expect(
        PerfilClinix.deMetadados({'perfil': 'profissional'}),
        PerfilClinix.profissional,
      );
    });

    test('perfil inválido ou ausente vira null, sem acesso', () {
      expect(PerfilClinix.deMetadados({'perfil': 'admin'}), isNull);
      expect(PerfilClinix.deMetadados({}), isNull);
    });
  });

  group('StatusAtendimento', () {
    test('valores batem com o enum do banco', () {
      expect(
        StatusAtendimento.values.map((s) => s.valorBanco).toList(),
        ['agendado', 'aguardando', 'em_atendimento', 'finalizado', 'cancelado'],
      );
    });
  });
}