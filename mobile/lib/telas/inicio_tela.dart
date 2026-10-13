import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../servicos/sessao.dart';
import 'consultar_tela.dart';
import 'ordens_tela.dart';

/// Tela principal após o login: abas "Consultar" e "Ordens de serviço".
class InicioTela extends StatefulWidget {
  const InicioTela({super.key});

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  int _aba = 0;

  Future<void> _sair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja encerrar a sessão?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirmar == true && mounted) await context.read<Sessao>().sair();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<Sessao>().usuario;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gestão de Ativos', style: TextStyle(fontWeight: FontWeight.w700)),
            if (usuario != null)
              Text(usuario.nome, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
          ],
        ),
        actions: [IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: _sair)],
      ),
      body: IndexedStack(index: _aba, children: const [ConsultarTela(), OrdensTela()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Consultar'),
          NavigationDestination(icon: Icon(Icons.build_outlined), label: 'Ordens de serviço'),
        ],
      ),
    );
  }
}
