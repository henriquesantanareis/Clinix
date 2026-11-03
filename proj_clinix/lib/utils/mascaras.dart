import 'package:flutter/services.dart';

// Aplica uma máscara em que cada "#" é um dígito. Ex.: '###.###.###-##'.
// Os separadores aparecem sozinhos conforme a pessoa digita.
String aplicarMascara(String digitos, String mascara) {
  final buffer = StringBuffer();
  var i = 0;
  for (final caractere in mascara.split('')) {
    if (i >= digitos.length) break;
    if (caractere == '#') {
      buffer.write(digitos[i]);
      i++;
    } else {
      buffer.write(caractere);
    }
  }
  return buffer.toString();
}

String _soDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

TextEditingValue _valorComCursorNoFim(String texto) => TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );

class MascaraCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) =>
      _valorComCursorNoFim(aplicarMascara(_soDigitos(novo.text), '###.###.###-##'));
}

class MascaraCep extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) =>
      _valorComCursorNoFim(aplicarMascara(_soDigitos(novo.text), '#####-###'));
}

// Fixo tem 10 dígitos; celular, 11. A máscara muda conforme a quantidade digitada.
class MascaraTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final digitos = _soDigitos(novo.text);
    final mascara = digitos.length <= 10 ? '(##) ####-####' : '(##) #####-####';
    return _valorComCursorNoFim(aplicarMascara(digitos, mascara));
  }
}