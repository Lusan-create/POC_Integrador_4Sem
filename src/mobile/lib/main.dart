import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'servicos/api.dart';
import 'telas/inicio_tela.dart';
import 'widgets/comuns.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await Api.instancia.carregar();
  runApp(const AppGestaoAtivos());
}

class AppGestaoAtivos extends StatelessWidget {
  const AppGestaoAtivos({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Ativos',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: corPrimaria, primary: corPrimaria, secondary: corDestaque),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        // Barra superior azul-marinho do Figma.
        appBarTheme: const AppBarTheme(
          backgroundColor: corMarinho,
          foregroundColor: Colors.white,
          centerTitle: true,
          toolbarHeight: 66,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: corFundoClaro,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      home: const InicioTela(),
    );
  }
}
