import 'package:flutter/material.dart';
import 'package:proj_clinix/apis/viacep_api.dart';
import 'package:proj_clinix/models/endereco_model.dart';

class ViaCepController {
  final ViaCepApi apiService = ViaCepApi();

  final ValueNotifier<EnderecoModel?> adress = ValueNotifier(null);
  final ValueNotifier<bool> isloading = ValueNotifier(false);
  final ValueNotifier<String?> erro = ValueNotifier(null);

  Future<void> searchAdress({required String cep}) async {
    isloading.value = true;
    erro.value = null;
    adress.value = null;

    try {
      final resultado = await apiService.buscarEndereco(cep: cep);

      if (resultado == null) {
        erro.value = 'CEP não encontrado. Preencha o endereço manualmente.';
      } else {
        adress.value = resultado;
      }
    } catch (_) {
      erro.value = 'Não foi possível consultar o CEP. Tente de novo ou preencha manualmente.';
    } finally {
      isloading.value = false;
    }
  }

  void dispose() {
    adress.dispose();
    isloading.dispose();
    erro.dispose();
  }
}