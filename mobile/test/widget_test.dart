import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leitor_qrcode/main.dart';

void main() {
  testWidgets('mostra o conteúdo lido do QR Code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ResultadoView(valor: 'PATRIMONIO-123')),
      ),
    );
    expect(find.text('PATRIMONIO-123'), findsOneWidget);
  });

  testWidgets('mostra aviso quando nada foi lido', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ResultadoView(valor: null))),
    );
    expect(find.textContaining('Nenhum QR Code lido'), findsOneWidget);
  });
}
