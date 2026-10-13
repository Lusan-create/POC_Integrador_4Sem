import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../modelos.dart';
import 'api.dart';

/// Estado de autenticação do app (quem está logado).
class Sessao extends ChangeNotifier {
  Sessao(this.api) {
    api.aoExpirarSessao = () {
      _usuario = null;
      notifyListeners();
    };
  }

  final Api api;
  final _cofre = const FlutterSecureStorage();
  Usuario? _usuario;
  bool _iniciada = false;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null && api.temToken;
  bool get iniciada => _iniciada;

  Future<void> iniciar() async {
    await api.carregar();
    final salvo = await _cofre.read(key: 'usuario');
    if (salvo != null && api.temToken) {
      _usuario = Usuario.deJson(jsonDecode(salvo));
    }
    _iniciada = true;
    notifyListeners();
  }

  Future<void> entrar(String email, String senha) async {
    final dados = await api.post(
      '/auth/login/',
      {'email': email.trim().toLowerCase(), 'password': senha},
      autenticar: false,
    );
    await api.salvarTokens(dados['access'], dados['refresh']);
    _usuario = Usuario.deJson(dados['usuario']);
    await _cofre.write(key: 'usuario', value: jsonEncode(_usuario!.paraJson()));
    notifyListeners();
  }

  Future<void> sair() async {
    await api.limparTokens();
    await _cofre.delete(key: 'usuario');
    _usuario = null;
    notifyListeners();
  }
}
