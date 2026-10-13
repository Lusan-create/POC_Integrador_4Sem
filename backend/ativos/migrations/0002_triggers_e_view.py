"""
Objetos de banco previstos no DER (seção "Restrições e objetos"):

* TRIGGER atualizado_em automático em ATIVO e USUARIO;
* TRIGGER em MANUTENCAO que atualiza última/próxima manutenção do ativo quando a OS é concluída;
* VIEW vw_ativo com os ativos não excluídos.
"""
from django.db import migrations

SQL = """
CREATE OR REPLACE FUNCTION fn_definir_atualizado_em() RETURNS trigger AS $$
BEGIN
    NEW.atualizado_em := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ativo_atualizado_em
    BEFORE UPDATE ON ativo
    FOR EACH ROW EXECUTE FUNCTION fn_definir_atualizado_em();

CREATE TRIGGER trg_usuario_atualizado_em
    BEFORE UPDATE ON usuario
    FOR EACH ROW EXECUTE FUNCTION fn_definir_atualizado_em();

CREATE OR REPLACE FUNCTION fn_manutencao_atualiza_ativo() RETURNS trigger AS $$
DECLARE
    v_ultima DATE;
BEGIN
    IF NEW.status = 'concluida' AND NEW.realizada_em IS NOT NULL THEN
        SELECT GREATEST(COALESCE(ultima_manutencao, NEW.realizada_em), NEW.realizada_em)
          INTO v_ultima
          FROM ativo WHERE id = NEW.ativo_id;

        UPDATE ativo
           SET ultima_manutencao = v_ultima,
               proxima_manutencao = CASE
                   WHEN NEW.proxima_prevista IS NOT NULL AND NEW.proxima_prevista >= v_ultima
                        THEN NEW.proxima_prevista
                   WHEN proxima_manutencao IS NOT NULL AND proxima_manutencao >= v_ultima
                        THEN proxima_manutencao
                   ELSE NULL
               END
         WHERE id = NEW.ativo_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_manutencao_atualiza_ativo
    AFTER INSERT OR UPDATE OF status, realizada_em, proxima_prevista ON manutencao
    FOR EACH ROW EXECUTE FUNCTION fn_manutencao_atualiza_ativo();

CREATE OR REPLACE VIEW vw_ativo AS
    SELECT a.id, a.identificacao, a.nome, a.descricao, a.status,
           c.nome AS categoria, l.nome AS localizacao, u.nome AS responsavel,
           a.ultima_manutencao, a.proxima_manutencao, a.criado_em, a.atualizado_em
      FROM ativo a
      JOIN categoria c ON c.id = a.categoria_id
      JOIN localizacao l ON l.id = a.localizacao_id
      LEFT JOIN usuario u ON u.id = a.responsavel_id
     WHERE a.deletado_em IS NULL;
"""

SQL_REVERSO = """
DROP VIEW IF EXISTS vw_ativo;
DROP TRIGGER IF EXISTS trg_manutencao_atualiza_ativo ON manutencao;
DROP FUNCTION IF EXISTS fn_manutencao_atualiza_ativo();
DROP TRIGGER IF EXISTS trg_usuario_atualizado_em ON usuario;
DROP TRIGGER IF EXISTS trg_ativo_atualizado_em ON ativo;
DROP FUNCTION IF EXISTS fn_definir_atualizado_em();
"""


class Migration(migrations.Migration):
    dependencies = [
        ("ativos", "0001_initial"),
        ("contas", "0001_initial"),
    ]

    operations = [migrations.RunSQL(SQL, SQL_REVERSO)]
