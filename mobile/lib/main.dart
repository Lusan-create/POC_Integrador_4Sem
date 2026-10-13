import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'servicos/api.dart';
import 'servicos/sessao.dart';
import 'telas/inicio_tela.dart';
import 'telas/login_tela.dart';
import 'widgets/comuns.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final sessao = Sessao(Api.instancia);
  await sessao.iniciar();
  runApp(ChangeNotifierProvider.value(value: sessao, child: const AppGestaoAtivos()));
}

class AppGestaoAtivos extends StatelessWidget {
  const AppGestaoAtivos({super.key});

  @override
  Widget build(BuildContext context) {
    final autenticado = context.select<Sessao, bool>((s) => s.autenticado);
    return MaterialApp(
      title: 'Gestão de Ativos',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorSchemeSeed: corPrimaria,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F5F8),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFFDFE2EA)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      // Troca automaticamente entre login e app conforme a sessão.
      home: autenticado ? const InicioTela() : const LoginTela(),
    );
  }
}
