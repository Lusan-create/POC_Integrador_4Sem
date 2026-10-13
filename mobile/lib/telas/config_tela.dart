import 'package:flutter/material.dart';

import '../servicos/api.dart';
import '../widgets/comuns.dart';

/// Permite apontar o app para a API rodando no PC (o IP muda conforme a rede).
class ConfigTela extends StatefulWidget {
  const ConfigTela({super.key});

  @override
  State<ConfigTela> createState() => _ConfigTelaState();
}

class _ConfigTelaState extends State<ConfigTela> {
  final _url = TextEditingController(text: Api.instancia.baseUrl);
  bool _testando = false;
  String? _resultado;
  bool _ok = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _testarESalvar() async {
    setState(() {
      _testando = true;
      _resultado = null;
    });
    await Api.instancia.definirBaseUrl(_url.text);
    try {
      // Sem login a API responde 401 — isso já prova que o servidor está acessível.
      await Api.instancia.get('/auth/eu/');
      _ok = true;
    } on ErroApi catch (e) {
      _ok = e.status != null;
      if (!_ok) _resultado = e.mensagem;
    }
    if (!mounted) return;
    setState(() {
      _testando = false;
      _resultado ??= _ok ? 'Servidor encontrado! Endereço salvo.' : null;
    });
    if (_ok) mostrarAviso(context, 'Endereço salvo.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Endereço do servidor')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Informe o endereço da API. No celular, use o IP do computador na mesma rede Wi-Fi, '
            'por exemplo: http://192.168.0.10:8000/api',
            style: TextStyle(color: Color(0xFF667085)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'URL da API'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _testando ? null : _testarESalvar,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(_testando ? 'Testando…' : 'Testar e salvar'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: 16),
            _ok
                ? Text(_resultado!, style: const TextStyle(color: Color(0xFF1F8A4C), fontWeight: FontWeight.w600))
                : CaixaErro(_resultado!),
          ],
        ],
      ),
    );
  }
}
