import 'package:flutter/material.dart';

import '../servicos/api.dart';
import '../widgets/comuns.dart';

/// Lista simples do Figma: título centralizado e um cartão por item vindo da API.
class ListaTela extends StatefulWidget {
  const ListaTela({super.key, required this.titulo, required this.caminho, required this.item, this.vazio = 'Nada cadastrado.'});

  final String titulo;
  final String caminho;
  final Widget Function(BuildContext, Map<String, dynamic>) item;
  final String vazio;

  @override
  State<ListaTela> createState() => _ListaTelaState();
}

class _ListaTelaState extends State<ListaTela> {
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final dados = await Api.instancia.get(widget.caminho, params: {'page_size': '100'});
      _itens = List<Map<String, dynamic>>.from(dados['results']);
      _erro = null;
    } on ErroApi catch (e) {
      _erro = e.mensagem;
    }
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        children: [
          Text(widget.titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: corMarinho)),
          const SizedBox(height: 24),
          if (_erro != null) CaixaErro(_erro!),
          if (_itens.isEmpty && _erro == null)
            Padding(padding: const EdgeInsets.all(32), child: Text(widget.vazio, textAlign: TextAlign.center)),
          for (final j in _itens)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(child: widget.item(context, j))),
        ],
      ),
    );
  }
}
