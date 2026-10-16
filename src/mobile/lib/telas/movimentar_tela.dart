import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicos/api.dart';
import '../widgets/comuns.dart';

/// RF07 — registra a mudança de local do ativo.
class MovimentarTela extends StatefulWidget {
  const MovimentarTela({super.key, required this.ativo});

  final Ativo ativo;

  @override
  State<MovimentarTela> createState() => _MovimentarTelaState();
}

class _MovimentarTelaState extends State<MovimentarTela> {
  final _observacao = TextEditingController();
  List<Localizacao> _locais = [];
  int? _destino;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarLocais();
  }

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  Future<void> _carregarLocais() async {
    try {
      final dados = await Api.instancia.get('/localizacoes/') as List;
      _locais = dados
          .map((j) => Localizacao.deJson(j))
          .where((l) => l.id != widget.ativo.localizacao.id)
          .toList();
    } on ErroApi catch (e) {
      _erro = e.mensagem;
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    if (_destino == null) {
      setState(() => _erro = 'Selecione o novo local.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await Api.instancia.post('/movimentacoes/', {
        'ativo_id': widget.ativo.id,
        'destino_id': _destino,
        'observacao': _observacao.text.trim(),
      });
      if (!mounted) return;
      mostrarAviso(context, 'Movimentação registrada.');
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
      appBar: AppBar(title: const Text('Registrar movimentação')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(widget.ativo.nome),
                    subtitle: Text('${widget.ativo.identificacao}\nLocal atual: ${widget.ativo.localizacao.nome}'),
                    isThreeLine: true,
                  ),
                ),
                const SizedBox(height: 16),
                if (_erro != null) CaixaErro(_erro!),
                DropdownButtonFormField<int>(
                  initialValue: _destino,
                  decoration: const InputDecoration(labelText: 'Novo local *'),
                  items: [for (final l in _locais) DropdownMenuItem(value: l.id, child: Text(l.nome))],
                  onChanged: (v) => setState(() => _destino = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _observacao,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observação', hintText: 'Motivo da movimentação'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: Text(_salvando ? 'Registrando…' : 'Registrar'),
                ),
              ],
            ),
    );
  }
}
