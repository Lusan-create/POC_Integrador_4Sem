import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Leitura de QR Code e códigos de barras (Code 128, EAN) pela câmera — RNF02.
/// Devolve o texto lido para a tela anterior.
class ScannerTela extends StatefulWidget {
  const ScannerTela({super.key});

  @override
  State<ScannerTela> createState() => _ScannerTelaState();
}

class _ScannerTelaState extends State<ScannerTela> {
  final _controle = MobileScannerController(
    formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13, BarcodeFormat.ean8],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _lido = false;

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  void _aoDetectar(BarcodeCapture captura) {
    if (_lido) return;
    final valor = captura.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (valor == null || valor.trim().isEmpty) return;
    _lido = true;
    Navigator.pop(context, valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ler código'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Lanterna',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controle.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controle,
            onDetect: _aoDetectar,
            errorBuilder: (context, erro) => _ErroCamera(erro: erro),
          ),
          // Moldura de mira
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF7BE0A0), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF2DF), borderRadius: BorderRadius.circular(8)),
              child: const Text(
                'Aponte a câmera para o QR Code ou código de barras',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFC26A00), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroCamera extends StatelessWidget {
  const _ErroCamera({required this.erro});

  final MobileScannerException erro;

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
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Digitar o código manualmente'),
            ),
          ],
        ),
      ),
    );
  }
}
