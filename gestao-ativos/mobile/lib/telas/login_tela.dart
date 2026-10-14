import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../servicos/api.dart';
import '../servicos/sessao.dart';
import '../widgets/comuns.dart';
import 'config_tela.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<Sessao>().entrar(_email.text, _senha.text);
    } on ErroApi catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      _senha.clear();
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Endereço do servidor',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfigTela())),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.qr_code_2, size: 48, color: corPrimaria),
                        const SizedBox(height: 8),
                        const Text('Entrar no sistema',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Gestão de Ativos',
                            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF667085))),
                        const SizedBox(height: 20),
                        if (_erro != null) CaixaErro(_erro!),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'E-mail'),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido.' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _senha,
                          obscureText: !_mostrarSenha,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            suffixIcon: IconButton(
                              icon: Icon(_mostrarSenha ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha.' : null,
                          onFieldSubmitted: (_) => _entrar(),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _carregando ? null : _entrar,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          child: _carregando
                              ? const SizedBox(
                                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Entrar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
