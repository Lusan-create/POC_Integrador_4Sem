import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicos/api.dart';
import '../widgets/comuns.dart';
import 'abrir_os_tela.dart';
import 'historico_tela.dart';
import 'movimentar_tela.dart';

/// Resultado da consulta: dados do ativo e ações disponíveis (RF04).
class AtivoTela extends StatefulWidget {
  const AtivoTela({super.key, required this.ativoInicial});

  final Ativo ativoInicial;

  @override
  State<AtivoTela> createState() => _AtivoTelaState();
}

class _AtivoTelaState extends State<AtivoTela> {
  late Ativo _ativo = widget.ativoInicial;

  Future<void> _recarregar() async {
    try {
      final dados = await Api.instancia.get('/ativos/${_ativo.id}/');
      if (mounted) setState(() => _ativo = Ativo.deJson(dados));
    } on ErroApi catch (e) {
      if (mounted) mostrarAviso(context, e.mensagem, erro: true);
    }
  }

  Future<void> _abrir(Widget tela) async {
    final alterou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => tela));
    if (alterou == true) await _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final a = _ativo;
    return Scaffold(
      appBar: AppBar(title: Text(a.identificacao)),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE5F4EA), borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.check_circle, color: Color(0xFF1F8A4C), size: 20),
                SizedBox(width: 8),
                Text('Ativo localizado', style: TextStyle(color: Color(0xFF1F8A4C), fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(a.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      SeloStatus(status: a.status, texto: a.statusExibicao),
                    ]),
                    const Divider(height: 24),
                    CampoInfo(rotulo: 'Patrimônio', valor: a.identificacao, mono: true),
                    CampoInfo(rotulo: 'Categoria', valor: a.categoria),
                    CampoInfo(rotulo: 'Local', valor: a.localizacao.nome),
                    CampoInfo(rotulo: 'Responsável', valor: a.responsavel ?? '—'),
                    Row(children: [
                      Expanded(child: CampoInfo(rotulo: 'Última manutenção', valor: formatarData(a.ultimaManutencao))),
                      Expanded(child: CampoInfo(rotulo: 'Próxima manutenção', valor: formatarData(a.proximaManutencao))),
                    ]),
                    if (a.descricao.isNotEmpty)
                      Text(a.descricao, style: const TextStyle(color: Color(0xFF667085))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (a.inativo)
              const CaixaErro('Ativo inativo: não é possível movimentar nem abrir ordem de serviço.')
            else ...[
              FilledButton.icon(
                onPressed: () => _abrir(MovimentarTela(ativo: a)),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Registrar movimentação'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _abrir(AbrirOSTela(ativo: a)),
                icon: const Icon(Icons.build_outlined),
                label: const Text('Abrir ordem de serviço'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _abrir(HistoricoTela(ativo: a)),
              icon: const Icon(Icons.history),
              label: const Text('Ver histórico'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
