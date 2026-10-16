import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../modelos.dart';
import '../servicos/api.dart';
import '../widgets/comuns.dart';
import 'ativo_tela.dart';

/// Aba CAMERA: a câmera abre ao entrar e lê o QR Code/código de barras (RF03 / RNF02 / RNF04).
/// O botão no canto superior direito permite digitar o código manualmente.
class ConsultarTela extends StatefulWidget {
  const ConsultarTela({super.key});

  @override
  State<ConsultarTela> createState() => _ConsultarTelaState();
}

class _ConsultarTelaState extends State<ConsultarTela> {
  final _controle = MobileScannerController(
    formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.ean8],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _carregando = false;

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  void _aoDetectar(BarcodeCapture captura) {
    final valor = captura.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (valor != null && valor.trim().isNotEmpty) _consultar(valor.trim());
  }

  Future<void> _consultar(String codigo) async {
    if (_carregando) return;
    setState(() => _carregando = true);
    await _controle.stop();
    try {
      final dados = await Api.instancia.get('/ativos/codigo/${Uri.encodeComponent(codigo)}/');
      if (!mounted) return;
      final ativo = Ativo.deJson(dados);
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AtivoTela(ativoInicial: ativo)));
    } on ErroApi catch (e) {
      if (mounted) {
        mostrarAviso(context, e.status == 404 ? 'Nenhum ativo encontrado com o código "$codigo".' : e.mensagem,
            erro: true);
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
        // Câmera indisponível (ex.: sem permissão): a pesquisa manual continua funcionando.
        try {
          await _controle.start();
        } catch (_) {}
      }
    }
  }

  Future<void> _pesquisaManual() async {
    final campo = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Pesquisar ativo'),
        content: TextField(
          controller: campo,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(labelText: 'Código do ativo', hintText: 'Ex.: PT-000324'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, campo.text), child: const Text('Pesquisar')),
        ],
      ),
    );
    campo.dispose();
    if (codigo != null && codigo.trim().isNotEmpty) await _consultar(codigo.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          MobileScanner(
            controller: _controle,
            onDetect: _aoDetectar,
            errorBuilder: (context, erro) => _ErroCamera(erro: erro, aoPesquisar: _pesquisaManual),
          ),
          // Quadrado guia para posicionar o QR Code.
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _carregando ? const Center(child: CircularProgressIndicator(color: Colors.white)) : null,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'pesquisa-manual',
              tooltip: 'Pesquisar código manualmente',
              backgroundColor: Colors.white,
              foregroundColor: corMarinho,
              onPressed: _carregando ? null : _pesquisaManual,
              child: const Icon(Icons.search),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Text(
              'Posicione o QR Code dentro do quadrado',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroCamera extends StatelessWidget {
  const _ErroCamera({required this.erro, required this.aoPesquisar});

  final MobileScannerException erro;
  final VoidCallback aoPesquisar;

  @override
  Widget build(BuildContext context) {
    final semPermissao = erro.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              semPermissao
                  ? 'Permissão da câmera negada. Libere o acesso nas configurações do aparelho.'
                  : 'Não foi possível usar a câmera neste dispositivo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: aoPesquisar, child: const Text('Digitar o código manualmente')),
          ],
        ),
      ),
    );
  }
}
