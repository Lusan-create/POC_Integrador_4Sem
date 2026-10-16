import 'package:flutter/material.dart';

import '../modelos.dart';
import '../widgets/comuns.dart';
import 'ativo_tela.dart';
import 'config_tela.dart';
import 'consultar_tela.dart';
import 'lista_tela.dart';
import 'ordens_tela.dart';

/// Tela principal no layout do Figma: barra azul com menu (Usuários, OS, servidor) e abas CAMERA · ATIVOS.
class InicioTela extends StatefulWidget {
  const InicioTela({super.key});

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  int _aba = 0; // abre na câmera, o fluxo principal

  void _abrir(Widget tela) {
    Navigator.pop(context); // fecha o menu
    Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Ativos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 13),
            child: CircleAvatar(radius: 17.5, backgroundColor: corAzulClaro, child: Icon(Icons.person, color: corMarinho)),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: corMarinho),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('Gestão de Ativos', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Usuários'),
              onTap: () => _abrir(Scaffold(
                appBar: AppBar(title: const Text('Usuários')),
                body: ListaTela(
                  titulo: 'USUÁRIOS',
                  caminho: '/usuarios/',
                  vazio: 'Nenhum usuário cadastrado.',
                  item: (_, j) => ListTile(
                    leading: const Icon(Icons.person_outline, color: corMarinho),
                    title: Text(j['nome'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${j['email']} · ${j['cargo_exibicao']}'),
                  ),
                ),
              )),
            ),
            ListTile(
              leading: const Icon(Icons.build_outlined),
              title: const Text('Ordens de serviço'),
              onTap: () => _abrir(Scaffold(appBar: AppBar(title: const Text('Ordens de serviço')), body: const OrdensTela())),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Endereço do servidor'),
              onTap: () => _abrir(const ConfigTela()),
            ),
          ],
        ),
      ),
      // Sem IndexedStack: ao sair da aba CAMERA a câmera é desligada; ao voltar, abre de novo.
      body: _aba == 0
          ? const ConsultarTela()
          : ListaTela(
              titulo: 'ATIVOS',
              caminho: '/ativos/',
              vazio: 'Nenhum ativo cadastrado.',
              item: (context, j) {
                final ativo = Ativo.deJson(j);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(ativo.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${ativo.identificacao} · ${ativo.localizacao.nome}'),
                  trailing: SeloStatus(status: ativo.status, texto: ativo.statusExibicao),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => AtivoTela(ativoInicial: ativo))),
                );
              },
            ),
      // Barra inferior azul-marinho do Figma.
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: corMarinho,
          indicatorColor: corPrimaria,
          height: 66,
          iconTheme: WidgetStateProperty.all(const IconThemeData(color: Colors.white)),
          labelTextStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        child: NavigationBar(
          selectedIndex: _aba,
          onDestinationSelected: (i) => setState(() => _aba = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'CAMERA'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'ATIVOS'),
          ],
        ),
      ),
    );
  }
}
