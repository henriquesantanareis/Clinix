class EnderecoModel {
  const EnderecoModel({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.uf
  });

  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String uf;

  factory EnderecoModel.fromJson(Map<String, dynamic> json) => EnderecoModel(
    cep: (json['cep'] ?? '') as String,
    logradouro: (json['logradouro'] ?? '') as String,
    bairro: (json['bairro'] ?? '') as String,
    cidade: (json['localidade'] ?? '') as String,
    uf: (json['uf'] ?? '') as String,
  );
  
}