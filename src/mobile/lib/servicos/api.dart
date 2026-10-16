import 'dart:async';
import 'dart:convert';

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

/// Cliente HTTP da API Django (POC sem login: as requisições não levam token).
class Api {
  Api._();
  static final Api instancia = Api._();

  /// Endereço padrão — pode ser trocado em tempo de build:
  /// flutter run --dart-define=API_URL=http://192.168.0.10:8000/api
  static const urlPadrao = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000/api');
  static const _chaveUrl = 'api_url';

  String _baseUrl = urlPadrao;

  String get baseUrl => _baseUrl;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_chaveUrl) ?? urlPadrao;
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

  // ------------------------------------------------------------ requisições

  Future<dynamic> get(String caminho, {Map<String, String>? params}) =>
      _enviar('GET', caminho, params: params);

  Future<dynamic> post(String caminho, Map<String, dynamic> corpo) =>
      _enviar('POST', caminho, corpo: corpo);

  Future<dynamic> patch(String caminho, Map<String, dynamic> corpo) =>
      _enviar('PATCH', caminho, corpo: corpo);

  Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    Map<String, dynamic>? corpo,
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$_baseUrl$caminho').replace(queryParameters: params);
    final cabecalhos = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    http.Response resposta;
    try {
      final req = http.Request(metodo, uri)..headers.addAll(cabecalhos);
      if (corpo != null) req.body = jsonEncode(corpo);
      final stream = await req.send().timeout(const Duration(seconds: 15));
      resposta = await http.Response.fromStream(stream);
    } on TimeoutException {
      throw ErroApi('O servidor ($_baseUrl) demorou para responder. Confira o endereço em ☰ → Endereço do servidor.');
    } catch (_) {
      throw ErroApi('Sem conexão com o servidor ($_baseUrl). Confira o Wi-Fi e o endereço em ☰ → Endereço do servidor.');
    }

    final texto = utf8.decode(resposta.bodyBytes);
    final dados = texto.isEmpty ? null : _tentarJson(texto);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return dados;
    throw _converterErro(resposta.statusCode, dados);
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
      404 => 'Registro não encontrado.',
      >= 500 => 'Erro no servidor. Tente novamente em instantes.',
      _ => detalhe ?? (campos.values.isNotEmpty ? campos.values.first : 'Não foi possível concluir a operação.'),
    };
    return ErroApi(mensagem, status: status, campos: campos);
  }
}
