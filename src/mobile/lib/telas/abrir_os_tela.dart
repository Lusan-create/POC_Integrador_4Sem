import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicos/api.dart';
import '../widgets/comuns.dart';

/// RF08 — abre uma ordem de serviço para o ativo.
class AbrirOSTela extends StatefulWidget {
  const AbrirOSTela({super.key, required this.ativo});

  final Ativo ativo;

  @override
  State<AbrirOSTela> createState() => _AbrirOSTelaState();
}

class _AbrirOSTelaState extends State<AbrirOSTela> {
  final _descricao = TextEditingController();
  String _tipo = 'corretiva';
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_descricao.text.trim().isEmpty) {
      setState(() => _erro = 'Descreva o problema ou serviço.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final os = await Api.instancia.post('/manutencoes/', {
        'ativo_id': widget.ativo.id,
        'tipo': _tipo,
        'descricao': _descricao.text.trim(),
      });
      if (!mounted) return;
      mostrarAviso(context, 'Ordem de serviço #${os['id']} aberta.');
      Navigator.pop(context, true);
    } on ErroApi catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abrir ordem de serviço')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(widget.ativo.nome),
              subtitle: Text('${widget.ativo.identificacao} · ${widget.ativo.localizacao.nome}'),
            ),
          ),
          const SizedBox(height: 16),
          if (_erro != null) CaixaErro(_erro!),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'corretiva', label: Text('Corretiva'), icon: Icon(Icons.build)),
              ButtonSegment(value: 'preventiva', label: Text('Preventiva'), icon: Icon(Icons.event_available)),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descricao,
            maxLength: 500,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descrição *',
              hintText: 'Ex.: Computador não liga, verificar fonte.',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _salvando ? null : _salvar,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(_salvando ? 'Abrindo…' : 'Abrir OS'),
          ),
        ],
      ),
    );
  }
}
