/// Modelos simples que espelham as respostas JSON da API.
library;

class Usuario {
  Usuario({required this.id, required this.nome, required this.email, required this.cargo});

  factory Usuario.deJson(Map<String, dynamic> j) =>
      Usuario(id: j['id'], nome: j['nome'], email: j['email'], cargo: j['cargo'] ?? 'user');

  final int id;
  final String nome;
  final String email;
  final String cargo;

  bool get ehAdmin => cargo == 'admin';

  Map<String, dynamic> paraJson() => {'id': id, 'nome': nome, 'email': email, 'cargo': cargo};
}

class Localizacao {
  Localizacao({required this.id, required this.nome, this.descricao});

  factory Localizacao.deJson(Map<String, dynamic> j) =>
      Localizacao(id: j['id'], nome: j['nome'], descricao: j['descricao']);

  final int id;
  final String nome;
  final String? descricao;
}

class Ativo {
  Ativo({
    required this.id,
    required this.identificacao,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.localizacao,
    required this.status,
    required this.statusExibicao,
    this.responsavel,
    this.ultimaManutencao,
    this.proximaManutencao,
  });

  factory Ativo.deJson(Map<String, dynamic> j) => Ativo(
        id: j['id'],
        identificacao: j['identificacao'],
        nome: j['nome'],
        descricao: j['descricao'] ?? '',
        categoria: j['categoria']['nome'],
        localizacao: Localizacao.deJson(j['localizacao']),
        responsavel: j['responsavel']?['nome'],
        status: j['status'],
        statusExibicao: j['status_exibicao'],
        ultimaManutencao: j['ultima_manutencao'],
        proximaManutencao: j['proxima_manutencao'],
      );

  final int id;
  final String identificacao;
  final String nome;
  final String descricao;
  final String categoria;
  final Localizacao localizacao;
  final String? responsavel;
  final String status;
  final String statusExibicao;
  final String? ultimaManutencao;
  final String? proximaManutencao;

  bool get inativo => status == 'inativo';
}

class OrdemServico {
  OrdemServico({
    required this.id,
    required this.ativoId,
    required this.ativoIdentificacao,
    required this.ativoNome,
    required this.tipo,
    required this.tipoExibicao,
    required this.status,
    required this.statusExibicao,
    required this.descricao,
    required this.abertaEm,
    this.realizadaEm,
    this.custo,
    this.registradoPor,
  });

  factory OrdemServico.deJson(Map<String, dynamic> j) => OrdemServico(
        id: j['id'],
        ativoId: j['ativo']['id'],
        ativoIdentificacao: j['ativo']['identificacao'],
        ativoNome: j['ativo']['nome'],
        tipo: j['tipo'],
        tipoExibicao: j['tipo_exibicao'],
        status: j['status'],
        statusExibicao: j['status_exibicao'],
        descricao: j['descricao'] ?? '',
        abertaEm: DateTime.parse(j['aberta_em']).toLocal(),
        realizadaEm: j['realizada_em'],
        custo: j['custo'],
        registradoPor: j['registrado_por']?['nome'],
      );

  final int id;
  final int ativoId;
  final String ativoIdentificacao;
  final String ativoNome;
  final String tipo;
  final String tipoExibicao;
  final String status;
  final String statusExibicao;
  final String descricao;
  final DateTime abertaEm;
  final String? realizadaEm;
  final String? custo;
  final String? registradoPor;

  bool get pendente => status == 'aberta' || status == 'em_andamento';
}

/// Item do histórico do ativo: movimentação ou ordem de serviço.
class EventoHistorico {
  EventoHistorico({required this.tipo, required this.data, required this.registro});

  factory EventoHistorico.deJson(Map<String, dynamic> j) => EventoHistorico(
        tipo: j['tipo'],
        data: DateTime.parse(j['data']).toLocal(),
        registro: Map<String, dynamic>.from(j['registro']),
      );

  final String tipo;
  final DateTime data;
  final Map<String, dynamic> registro;

  bool get ehMovimentacao => tipo == 'movimentacao';
}
