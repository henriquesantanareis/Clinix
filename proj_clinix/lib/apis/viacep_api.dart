import 'package:dio/dio.dart';
import 'package:proj_clinix/config/viacep_config.dart';
import 'package:proj_clinix/models/endereco_model.dart';

class ViaCepApi {
  ViaCepApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  final Dio _dio;

  /// Retorna o endereço, ou null se o CEP não existir.
  /// Lança exceção se a consulta falhar (sem rede, timeout, serviço fora).
  Future<EnderecoModel?> buscarEndereco({required String cep}) async {
    final somenteNumeros = cep.replaceAll(RegExp(r'\D'), '');
    if (somenteNumeros.length != 8) {
      throw ArgumentError('CEP deve ter 8 dígitos');
    }

    try {
      final resposta = await _dio.get<Map<String, dynamic>>(
        ViaCepConfig.baseUrl(somenteNumeros),
      );

      final dados = resposta.data;
      if (dados == null) throw Exception('Resposta vazia do ViaCEP');

      if (_naoEncontrado(dados)) return null;

      return EnderecoModel.fromJson(dados);
    } on DioException catch (erro) {
      // Algumas respostas de erro chegam com status 400: isso é CEP não encontrado,
      // e não falha de conexão.
      if (erro.response?.statusCode == 400) return null;
      rethrow;
    }
  }

  // O ViaCEP devolve "erro" como texto "true" no CEP inexistente, e às vezes como booleano.
  bool _naoEncontrado(Map<String, dynamic> dados) {
    final erro = dados['erro'];
    return erro == true || erro == 'true';
  }
}
