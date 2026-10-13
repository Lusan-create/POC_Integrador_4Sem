import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicos/api.dart';
import '../widgets/comuns.dart';
import 'atualizar_os.dart';

/// RF09 — histórico de movimentações e ordens de serviço do ativo.
class HistoricoTela extends StatefulWidget {
  const HistoricoTela({super.key, required this.ativo});

  final Ativo ativo;

  @override
  State<HistoricoTela> createState() => _HistoricoTelaState();
}

class _HistoricoTelaState extends State<HistoricoTela> {
  List<EventoHistorico> _eventos = [];
  bool _carregando = true;
  bool _alterou = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final dados = await Api.instancia.get('/ativos/${widget.ativo.id}/historico/');
      _eventos = (dados['eventos'] as List).map((e) => EventoHistorico.deJson(e)).toList();
      _erro = null;
    } on ErroApi catch (e) {
      _erro = e.mensagem;
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _atualizarOS(Map<String, dynamic> registro) async {
    final salvo = await mostrarAtualizarOS(context, OrdemServico.deJson(registro));
    if (salvo) {
      _alterou = true;
      await _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _alterou);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Histórico · ${widget.ativo.identificacao}')),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _carregar,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_erro != null) CaixaErro(_erro!),
                    if (_eventos.isEmpty && _erro == null)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Nenhum registro no histórico.', textAlign: TextAlign.center),
                      ),
                    for (final e in _eventos) _ItemHistorico(evento: e, aoAtualizar: _atualizarOS),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ItemHistorico extends StatelessWidget {
  const _ItemHistorico({required this.evento, required this.aoAtualizar});

  final EventoHistorico evento;
  final void Function(Map<String, dynamic>) aoAtualizar;

  @override
  Widget build(BuildContext context) {
    final r = evento.registro;
    final autor = r['registrado_por']?['nome'] ?? 'usuário removido';
    final rodape = '${formatarDataHora(evento.data)} · $autor';

    if (evento.ehMovimentacao) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.swap_horiz)),
          title: Text('${r['origem']['nome']} → ${r['destino']['nome']}'),
          subtitle: Text([if ((r['observacao'] ?? '').isNotEmpty) r['observacao'], rodape].join('\n')),
        ),
      );
    }

    final pendente = r['status'] == 'aberta' || r['status'] == 'em_andamento';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFF2DF),
                child: Icon(Icons.build_outlined, color: Color(0xFFC26A00)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('OS #${r['id']} — ${r['tipo_exibicao']}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              SeloStatus(status: r['status'], texto: r['status_exibicao']),
            ]),
            const SizedBox(height: 8),
            Text(r['descricao'] ?? ''),
            if (r['realizada_em'] != null)
              Text('Realizada em ${formatarData(r['realizada_em'])} · Custo ${formatarMoeda(r['custo'])}',
                  style: const TextStyle(color: Color(0xFF667085))),
            const SizedBox(height: 4),
            Text(rodape, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
            if (pendente)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => aoAtualizar(r), child: const Text('Atualizar OS')),
              ),
          ],
        ),
      ),
    );
  }
}
