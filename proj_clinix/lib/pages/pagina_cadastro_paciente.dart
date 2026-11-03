import 'package:flutter/material.dart';
import 'package:proj_clinix/apis/viacep_api.dart';
import 'package:proj_clinix/data/agenda_repository.dart';
import 'package:proj_clinix/models/endereco_model.dart';
import 'package:proj_clinix/utils/mascaras.dart';
import 'package:proj_clinix/widgets/componentes_atendimento.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaginaCadastroPaciente extends StatefulWidget {
  const PaginaCadastroPaciente({super.key, required this.aoSalvar});

  // Chamado só depois que o banco confirma o cadastro.
  final VoidCallback aoSalvar;

  @override
  State<PaginaCadastroPaciente> createState() => _EstadoCadastroPaciente();
}

class _EstadoCadastroPaciente extends State<PaginaCadastroPaciente> {
  final _formKey = GlobalKey<FormState>();
  final _repositorio = AgendaRepository();
  final _viacep = ViaCepApi();

  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cpf = TextEditingController();
  final _cep = TextEditingController();
  final _logradouro = TextEditingController();
  final _numero = TextEditingController();
  final _complemento = TextEditingController();
  final _bairro = TextEditingController();
  final _cidade = TextEditingController();
  final _uf = TextEditingController();

  bool _buscandoCep = false;
  bool _cepInexistente = false;
  bool _salvando = false;
  String? _avisoCep;
  String? _erroCpf;
  String? _erroGeral;

  @override
  void dispose() {
    for (final c in [
      _nome,
      _telefone,
      _cpf,
      _cep,
      _logradouro,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _uf,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Chamado a cada alteração do CEP. Só consulta quando tiver 8 dígitos.
  Future<void> _buscarCep(String valor) async {
    final digitos = valor.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) {
      if (_cepInexistente || _avisoCep != null) {
        setState(() {
          _cepInexistente = false;
          _avisoCep = null;
        });
      }
      return;
    }

    setState(() {
      _buscandoCep = true;
      _avisoCep = null;
      _cepInexistente = false;
    });
    try {
      final EnderecoModel? endereco = await _viacep.buscarEndereco(
        cep: digitos,
      );
      if (!mounted) return;
      if (endereco == null) {
        setState(() {
          _cepInexistente = true;
          _avisoCep = 'CEP não encontrado. Confira o número ou apague o CEP.';
        });
      } else {
        setState(() {
          _logradouro.text = endereco.logradouro;
          _bairro.text = endereco.bairro;
          _cidade.text = endereco.cidade;
          _uf.text = endereco.uf;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _avisoCep = 'Não foi possível consultar o CEP. Você pode salvar e preencher depois.',
      );
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() {
      _erroCpf = null;
      _erroGeral = null;
    });
    if (!_formKey.currentState!.validate()) return;
    if (_cepInexistente) {
      setState(
        () => _erroGeral = 'O CEP não existe. Corrija o número ou apague o CEP antes de salvar.',
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      await _repositorio.cadastrarPaciente(
        nome: _nome.text,
        cpf: _cpf.text,
        telefone: _telefone.text,
        cep: _cep.text,
        logradouro: _logradouro.text,
        numero: _numero.text,
        complemento: _complemento.text,
        bairro: _bairro.text,
        cidade: _cidade.text,
        uf: _uf.text,
      );
      if (!mounted) return;
      _limpar();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Paciente cadastrado.')));
      widget.aoSalvar();
    } on PostgrestException catch (erro) {
      if (!mounted) return;
      setState(() {
        if (erro.code == '23505') {
          _erroCpf = 'Já existe um paciente com este CPF.';
        } else {
          _erroGeral = 'Não foi possível cadastrar o paciente. Tente de novo.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erroGeral =
            'Não foi possível cadastrar o paciente. Tente de novo.',
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // Deixa o formulário vazio para o próximo cadastro.
  void _limpar() {
    for (final c in [
      _nome,
      _telefone,
      _cpf,
      _cep,
      _logradouro,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _uf,
    ]) {
      c.clear();
    }
    _formKey.currentState?.reset();
    setState(() {
      _avisoCep = null;
      _erroCpf = null;
      _erroGeral = null;
      _cepInexistente = false;
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CabecalhoAtendimento(
                titulo: 'Novo paciente',
                descricao: 'Cadastre o paciente antes de agendar a consulta.',
              ),
              TextFormField(
                key: const Key('cadastro-nome'),
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  counterText: '',
                  hintText: 'Ex.: Maria da Silva, João Pereira',
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefone,
                keyboardType: TextInputType.phone,
                maxLength: 15,
                inputFormatters: [MascaraTelefone()],
                decoration: const InputDecoration(
                  labelText: 'Telefone *',
                  counterText: '',
                  hintText: 'Ex.: (11) 91234-5678',
                ),
                validator: (v) {
                  final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digitos.isEmpty) return 'Informe o telefone.';
                  return digitos.length == 10 || digitos.length == 11
                      ? null
                      : 'O telefone deve ter DDD e 10 ou 11 números.';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cpf,
                keyboardType: TextInputType.number,
                maxLength: 14,
                inputFormatters: [MascaraCpf()],
                decoration: InputDecoration(
                  labelText: 'CPF *',
                  counterText: '',
                  hintText: 'Ex.: 123.456.789-00',
                  errorText: _erroCpf,
                ),
                validator: (v) {
                  final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digitos.isEmpty) return 'Informe o CPF.';
                  return digitos.length == 11
                      ? null
                      : 'O CPF deve ter 11 dígitos.';
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cep,
                keyboardType: TextInputType.number,
                maxLength: 9,
                inputFormatters: [MascaraCep()],
                onChanged: _buscarCep,
                decoration: InputDecoration(
                  labelText: 'CEP (opcional)',
                  counterText: '',
                  hintText: 'Ex.: 12345-678',
                  helperText: _buscandoCep
                      ? 'Buscando endereço...'
                      : (_cepInexistente ? null : _avisoCep),
                  errorText: _cepInexistente ? 'CEP não encontrado.' : null,
                ),
                validator: (v) {
                  final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digitos.isEmpty) return null;
                  return digitos.length == 8
                      ? null
                      : 'O CEP deve ter 8 dígitos.';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _logradouro,
                textCapitalization: TextCapitalization.words,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Logradouro',
                  counterText: '',
                  hintText: 'Ex.: Rua das Flores, Avenida Brasil',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numero,
                      keyboardType: TextInputType.text,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Número',
                        counterText: '',
                        hintText: 'Ex.: 123, 45A, S/N',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _complemento,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Complemento',
                        counterText: '',
                        hintText: 'Ex.: Apto 101, Bloco B, Fundos',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bairro,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Bairro',
                  counterText: '',
                  hintText: 'Ex.: Centro, Vila Nova, Jardim das Flores',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cidade,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Cidade',
                        counterText: '',
                        hintText:
                            'Ex.: São Paulo, Rio de Janeiro, Belo Horizonte',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _uf,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        counterText: '',
                        hintText: 'Ex.: SP, RJ, MG',
                      ),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return null;
                        return t.length == 2 ? null : 'Use a sigla, como SP.';
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_erroGeral != null) ...[
                Text(_erroGeral!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                key: const Key('salvar-paciente'),
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(_salvando ? 'Salvando...' : 'Salvar paciente'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
