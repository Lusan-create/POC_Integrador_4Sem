import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Paleta do Figma (4SEM_INTEGRADOR).
const corMarinho = Color(0xFF1B325F);
const corPrimaria = Color(0xFF3A89C9);
const corAzulClaro = Color(0xFF9CC4E4);
const corFundoClaro = Color(0xFFE9F2F9);
const corDestaque = Color(0xFFF26C4F);

String formatarData(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final p = iso.substring(0, 10).split('-');
  return '${p[2]}/${p[1]}/${p[0]}';
}

String formatarDataHora(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);

String formatarMoeda(String? valor) {
  if (valor == null) return '—';
  return NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(double.tryParse(valor) ?? 0);
}

/// Selo colorido com a situação do ativo ou da OS.
class SeloStatus extends StatelessWidget {
  const SeloStatus({super.key, required this.status, required this.texto});

  final String status;
  final String texto;

  static const _cores = {
    'disponivel': (Color(0xFFE5F4EA), Color(0xFF1F8A4C)),
    'concluida': (Color(0xFFE5F4EA), Color(0xFF1F8A4C)),
    'em_uso': (Colors.white, corPrimaria),
    'em_andamento': (Colors.white, corPrimaria),
    'em_manutencao': (Color(0xFFFDE6E0), Color(0xFFC8462B)),
    'aberta': (Color(0xFFFDE6E0), Color(0xFFC8462B)),
  };

  @override
  Widget build(BuildContext context) {
    final (fundo, texto_) = _cores[status] ?? (const Color(0xFFECEEF2), const Color(0xFF667085));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(99)),
      child: Text(texto, style: TextStyle(color: texto_, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Linha "rótulo / valor" usada na ficha do ativo.
class CampoInfo extends StatelessWidget {
  const CampoInfo({super.key, required this.rotulo, required this.valor, this.mono = false});

  final String rotulo;
  final String valor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

void mostrarAviso(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: erro ? const Color(0xFFC0392B) : const Color(0xFF1F8A4C),
      behavior: SnackBarBehavior.floating,
    ));
}

class CaixaErro extends StatelessWidget {
  const CaixaErro(this.mensagem, {super.key});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(8)),
      child: Text(mensagem, style: const TextStyle(color: Color(0xFFC0392B))),
    );
  }
}
