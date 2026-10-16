import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modelos.dart';
import '../servicos/api.dart';
import '../widgets/comuns.dart';

/// Abre um painel para mudar a situação da OS (em andamento / concluída / cancelada).
/// Retorna true se a OS foi salva.
Future<bool> mostrarAtualizarOS(BuildContext context, OrdemServico os) async {
  final salvo = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AtualizarOS(os: os),
  );
  return salvo ?? false;
}

class _AtualizarOS extends StatefulWidget {
  const _AtualizarOS({required this.os});

  final OrdemServico os;

  @override
  State<_AtualizarOS> createState() => _AtualizarOSState();
}

class _AtualizarOSState extends State<_AtualizarOS> {
  late String _status = widget.os.status == 'aberta' ? 'em_andamento' : widget.os.status;
  DateTime _realizada = DateTime.now();
  DateTime? _proxima;
  final _custo = TextEditingController();
  bool _salvando = false;
  String? _erro;

  static final _iso = DateFormat('yyyy-MM-dd');
  static final _br = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _custo.dispose();
    super.dispose();
  }

  Future<DateTime?> _escolherData(DateTime inicial, {DateTime? minima, DateTime? maxima}) {
    return showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: minima ?? DateTime(2000),
      lastDate: maxima ?? DateTime(2100),
    );
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });
    final corpo = <String, dynamic>{'status': _status};
    if (_status == 'concluida') {
      corpo['realizada_em'] = _iso.format(_realizada);
      corpo['proxima_prevista'] = _proxima == null ? null : _iso.format(_proxima!);
      final custo = _custo.text.trim().replaceAll(',', '.');
      corpo['custo'] = custo.isEmpty ? null : custo;
    }
    try {
      await Api.instancia.patch('/manutencoes/${widget.os.id}/', corpo);
      if (!mounted) return;
      mostrarAviso(context, 'OS #${widget.os.id} atualizada.');
      Navigator.pop(context, true);
    } on ErroApi catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Atualizar OS #${widget.os.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${widget.os.ativoIdentificacao} — ${widget.os.ativoNome}',
                style: const TextStyle(color: Color(0xFF667085))),
            const SizedBox(height: 16),
            if (_erro != null) CaixaErro(_erro!),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Situação'),
              items: const [
                DropdownMenuItem(value: 'aberta', child: Text('Aberta')),
                DropdownMenuItem(value: 'em_andamento', child: Text('Em andamento')),
                DropdownMenuItem(value: 'concluida', child: Text('Concluída')),
                DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            if (_status == 'concluida') ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Realizada em *'),
                subtitle: Text(_br.format(_realizada)),
                onTap: () async {
                  final d = await _escolherData(_realizada, maxima: DateTime.now());
                  if (d != null) {
                    setState(() {
                      _realizada = d;
                      if (_proxima != null && _proxima!.isBefore(d)) _proxima = null;
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_repeat),
                title: const Text('Próxima manutenção'),
                subtitle: Text(_proxima == null ? 'Não definida' : _br.format(_proxima!)),
                onTap: () async {
                  final d = await _escolherData(_proxima ?? _realizada.add(const Duration(days: 180)),
                      minima: _realizada);
                  if (d != null) setState(() => _proxima = d);
                },
              ),
              TextField(
                controller: _custo,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: r'Custo (R$)', hintText: '0,00'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(_salvando ? 'Salvando…' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
