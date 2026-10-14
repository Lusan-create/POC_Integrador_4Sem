import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Paleta do Figma (4SEM_INTEGRADOR > PAGINAS MOBILE > CORES)
const azulEscuro = Color(0xFF1B325F);
const azulMedio = Color(0xFF3A89C9);
const azulClaro = Color(0xFFE9F2F9);

void main() => runApp(const LeitorQrApp());

class LeitorQrApp extends StatelessWidget {
  const LeitorQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leitor QR Code',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: azulEscuro, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _aba = 1; // 0 USERS, 1 CAMERA, 2 ATIVOS
  String? _lido;

  void _onDetect(BarcodeCapture captura) {
    final valor = captura.barcodes.firstOrNull?.rawValue;
    if (valor == null || _aba != 1) return;
    setState(() {
      _lido = valor;
      _aba = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      const Center(child: Text('USERS')),
      // A câmera só fica ativa enquanto a aba CAMERA está aberta.
      _aba == 1 ? MobileScanner(onDetect: _onDetect) : const SizedBox.shrink(),
      ResultadoView(valor: _lido),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulEscuro,
        foregroundColor: Colors.white,
        toolbarHeight: 66,
        leading: const Icon(Icons.menu, size: 34),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 13),
            child: CircleAvatar(
              radius: 17.5,
              backgroundColor: Color(0xFFD9D9D9),
            ),
          ),
        ],
      ),
      body: telas[_aba],
      bottomNavigationBar: NavigationBar(
        height: 66,
        backgroundColor: azulEscuro,
        indicatorColor: azulMedio,
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(color: Colors.white, fontSize: 12),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person, color: Colors.white),
            label: 'USERS',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            label: 'CAMERA',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2, color: Colors.white),
            label: 'ATIVOS',
          ),
        ],
      ),
    );
  }
}

class ResultadoView extends StatelessWidget {
  const ResultadoView({super.key, required this.valor});

  final String? valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ATIVOS',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 36),
          Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: azulClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              valor ?? 'Nenhum QR Code lido. Use a aba CAMERA para ler um.',
              style: const TextStyle(fontSize: 16, color: azulEscuro),
            ),
          ),
        ],
      ),
    );
  }
}
