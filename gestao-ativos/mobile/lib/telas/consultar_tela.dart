import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicos/api.dart';
import '../widgets/comuns.dart';
import 'ativo_tela.dart';
import 'scanner_tela.dart';

/// Fluxo principal: ler o QR Code/código de barras ou digitar o código (RF03 / RNF04).
class ConsultarTela extends StatefulWidget {
  const ConsultarTela({super.key});

  @override
  State<ConsultarTela> createState() => _ConsultarTelaState();
}

class _ConsultarTelaState extends State<ConsultarTela> {
  final _codigo = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _abrirCamera() async {
    final lido = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ScannerTela()));
    if (lido != null && lido.trim().isNotEmpty) {
      _codigo.text = lido.trim();
      await _consultar();
    }
  }

  Future<void> _consultar() async {
    final codigo = _codigo.text.trim();
    if (codigo.isEmpty) {
      setState(() => _erro = 'Informe o código do ativo.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await Api.instancia.get('/ativos/codigo/${Uri.encodeComponent(codigo)}/');
      if (!mounted) return;
      final ativo = Ativo.deJson(dados);
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AtivoTela(ativoInicial: ativo)));
    } on ErroApi catch (e) {
      setState(() => _erro = e.status == 404 ? 'Nenhum ativo encontrado com o código "$codigo".' : e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Consultar ativo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Aponte a câmera para o QR Code ou código de barras da etiqueta.',
                    style: TextStyle(color: Color(0xFF667085))),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _carregando ? null : _abrirCamera,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Iniciar câmera'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('ou')),
                    Expanded(child: Divider()),
                  ]),
                ),
                if (_erro != null) CaixaErro(_erro!),
                TextField(
                  controller: _codigo,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(labelText: 'Código do ativo', hintText: 'Ex.: PT-000324'),
                  onSubmitted: (_) => _consultar(),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _carregando ? null : _consultar,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _carregando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Consultar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
