import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Erro amigável vindo da API (ou da falta de conexão com ela).
class ErroApi implements Exception {
  ErroApi(this.mensagem, {this.status, this.campos = const {}});

  final String mensagem;
  final int? status;
  final Map<String, String> campos;

  @override
  String toString() => mensagem;
}

/// Cliente HTTP da API Django. Guarda os tokens JWT no armazenamento seguro do aparelho.
class Api {
  Api._();
  static final Api instancia = Api._();

  /// Endereço padrão — pode ser trocado em tempo de build:
  /// flutter run --dart-define=API_URL=http://192.168.0.10:8000/api
  static const urlPadrao = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000/api');
  static const _chaveUrl = 'api_url';

  final _cofre = const FlutterSecureStorage();
  String _baseUrl = urlPadrao;
  String? _access;
  String? _refresh;
  Future<bool>? _renovando;

  /// Chamado quando a sessão expira e não é possível renovar.
  void Function()? aoExpirarSessao;

  String get baseUrl => _baseUrl;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_chaveUrl) ?? urlPadrao;
    _access = await _cofre.read(key: 'access');
    _refresh = await _cofre.read(key: 'refresh');
  }

  Future<void> definirBaseUrl(String url) async {
    var limpa = url.trim();
    while (limpa.endsWith('/')) {
      limpa = limpa.substring(0, limpa.length - 1);
    }
    _baseUrl = limpa;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveUrl, limpa);
  }

  bool get temToken => _access != null;

  Future<void> salvarTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    await _cofre.write(key: 'access', value: access);
    await _cofre.write(key: 'refresh', value: refresh);
  }

  Future<void> limparTokens() async {
    _access = null;
    _refresh = null;
    await _cofre.delete(key: 'access');
    await _cofre.delete(key: 'refresh');
  }

  // ------------------------------------------------------------ requisições

  Future<dynamic> get(String caminho, {Map<String, String>? params}) =>
      _enviar('GET', caminho, params: params);

  Future<dynamic> post(String caminho, Map<String, dynamic> corpo, {bool autenticar = true}) =>
      _enviar('POST', caminho, corpo: corpo, autenticar: autenticar);

  Future<dynamic> patch(String caminho, Map<String, dynamic> corpo) =>
      _enviar('PATCH', caminho, corpo: corpo);

  Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? corpo,
    Map<String, String>? params,
    bool autenticar = true,
    bool repetida = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$caminho').replace(queryParameters: params);
    final cabecalhos = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (autenticar && _access != null) 'Authorization': 'Bearer $_access',
    };

    http.Response resposta;
    try {
      final req = http.Request(metodo, uri)..headers.addAll(cabecalhos);
      if (corpo != null) req.body = jsonEncode(corpo);
      final stream = await req.send().timeout(const Duration(seconds: 15));
      resposta = await http.Response.fromStream(stream);
    } on TimeoutException {
      throw ErroApi('O servidor demorou para responder. Verifique a rede e o endereço da API.');
    } catch (_) {
      throw ErroApi('Sem conexão com o servidor ($_baseUrl). Verifique o Wi-Fi e o endereço da API.');
    }

    // Token expirado: tenta renovar uma única vez.
    if (resposta.statusCode == 401 && autenticar && !repetida && _refresh != null) {
      if (await _renovarToken()) {
        return _enviar(metodo, caminho, corpo: corpo, params: params, repetida: true);
      }
      await limparTokens();
      aoExpirarSessao?.call();
      throw ErroApi('Sua sessão expirou. Entre novamente.', status: 401);
    }

    final texto = utf8.decode(resposta.bodyBytes);
    final dados = texto.isEmpty ? null : _tentarJson(texto);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return dados;
    throw _converterErro(resposta.statusCode, dados);
  }

  Future<bool> _renovarToken() {
    return _renovando ??= () async {
      try {
        final r = await http
            .post(Uri.parse('$_baseUrl/auth/renovar/'),
                headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': _refresh}))
            .timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) return false;
        final novo = jsonDecode(r.body)['access'] as String;
        await salvarTokens(novo, _refresh!);
        return true;
      } catch (_) {
        return false;
      } finally {
        _renovando = null;
      }
    }();
  }

  dynamic _tentarJson(String texto) {
    try {
      return jsonDecode(texto);
    } catch (_) {
      return null;
    }
  }

  ErroApi _converterErro(int status, dynamic dados) {
    final campos = <String, String>{};
    String? detalhe;
    if (dados is Map) {
      dados.forEach((chave, valor) {
        final msg = valor is List ? valor.join(' ') : valor.toString();
        if (chave == 'detail') {
          detalhe = msg;
        } else {
          campos[chave.toString()] = msg;
        }
      });
    }
    final mensagem = switch (status) {
      401 => detalhe ?? 'E-mail ou senha inválidos.',
      403 => detalhe ?? 'Você não tem permissão para esta ação.',
      404 => 'Registro não encontrado.',
      429 => 'Muitas tentativas. Aguarde um minuto e tente de novo.',
      >= 500 => 'Erro no servidor. Tente novamente em instantes.',
      _ => detalhe ?? (campos.values.isNotEmpty ? campos.values.first : 'Não foi possível concluir a operação.'),
    };
    return ErroApi(mensagem, status: status, campos: campos);
  }
}
