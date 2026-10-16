import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ativos/modelos.dart';
import 'package:gestao_ativos/widgets/comuns.dart';

void main() {
  test('formata data ISO no padrão brasileiro', () {
    expect(formatarData('2026-11-05T10:00:00Z'), '05/11/2026');
    expect(formatarData(null), '—');
  });

  test('usuário com cargo admin é administrador', () {
    final admin = Usuario.deJson({'id': 1, 'nome': 'Ana', 'email': 'ana@senai.br', 'cargo': 'admin'});
    final comum = Usuario.deJson({'id': 2, 'nome': 'Bia', 'email': 'bia@senai.br'});
    expect(admin.ehAdmin, isTrue);
    expect(comum.ehAdmin, isFalse);
  });

  testWidgets('selo mostra o texto do status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SeloStatus(status: 'disponivel', texto: 'Disponível'))),
    );
    expect(find.text('Disponível'), findsOneWidget);
  });
}
