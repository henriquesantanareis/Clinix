import 'package:dio/dio.dart';
import 'package:proj_clinix/config/viacep_config.dart';
import 'package:proj_clinix/models/endereco_model.dart';

class ViaCepApi {
  final Dio _dio = Dio();
  /// Retorna o endereço, ou null se o CEP não existir.
  /// Lança exceção se a consulta falhar (sem rede, timeout, serviço fora).
  Future<EnderecoModel?> buscarEndereco({required String cep}) async {
    final somenteNumeros = cep.replaceAll(RegExp(r'\D'), '');
    if (somenteNumeros.length != 8) {
      throw ArgumentError('CEP deve ter 8 dígitos');
    }

    final resposta = await _dio.get<Map<String, dynamic>>(
      ViaCepConfig.baseUrl(somenteNumeros),
    );

    final dados = resposta.data;
    if (dados == null) throw Exception('Resposta vazia do ViaCEP');

    // CEP inexistente volta com status 200 e o campo "erro"
    if (dados['erro'] == true) return null;

    return EnderecoModel.fromJson(dados);
  }
}