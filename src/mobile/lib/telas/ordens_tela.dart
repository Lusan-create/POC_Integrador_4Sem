import 'package:flutter/material.dart';

import '../modelos.dart';
import '../servicos/api.dart';
import '../widgets/comuns.dart';
import 'atualizar_os.dart';

/// Lista das ordens de serviço pendentes, para o técnico acompanhar e concluir.
class OrdensTela extends StatefulWidget {
  const OrdensTela({super.key});

  @override
  State<OrdensTela> createState() => _OrdensTelaState();
}

class _OrdensTelaState extends State<OrdensTela> {
  List<OrdemServico> _ordens = [];
  bool _somentePendentes = true;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = _ordens.isEmpty);
    try {
      final dados = await Api.instancia.get('/manutencoes/', params: {
        'page_size': '100',
        if (_somentePendentes) 'status__in': 'aberta,em_andamento',
      });
      _ordens = (dados['results'] as List).map((j) => OrdemServico.deJson(j)).toList();
      _erro = null;
    } on ErroApi catch (e) {
      _erro = e.mensagem;
    }
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Pendentes')),
              ButtonSegment(value: false, label: Text('Todas')),
            ],
            selected: {_somentePendentes},
            onSelectionChanged: (s) {
              setState(() => _somentePendentes = s.first);
              _carregar();
            },
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_erro != null) CaixaErro(_erro!),
                      if (_ordens.isEmpty && _erro == null)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Nenhuma ordem de serviço.', textAlign: TextAlign.center),
                        ),
                      for (final os in _ordens)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text('OS #${os.id} · ${os.ativoIdentificacao}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${os.ativoNome}\n${os.descricao}\n'
                                '${os.tipoExibicao} · aberta em ${formatarDataHora(os.abertaEm)}'),
                            isThreeLine: true,
                            trailing: SeloStatus(status: os.status, texto: os.statusExibicao),
                            onTap: os.pendente
                                ? () async {
                                    if (await mostrarAtualizarOS(context, os)) _carregar();
                                  }
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
