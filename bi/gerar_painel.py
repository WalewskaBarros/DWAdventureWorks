"""
Gera o painel de BI da Adventure Works (docs/index.html) a partir dos marts do dbt.

O painel é um único arquivo HTML com Plotly.js e os dados embutidos (compactados),
para abrir em qualquer navegador sem login e ser publicado no GitHub Pages.

Fontes suportadas:
  --fonte databricks  lê direto do SQL warehouse (variáveis de ambiente
                      DATABRICKS_SERVER_HOSTNAME, DATABRICKS_HTTP_PATH e DATABRICKS_TOKEN)
  --fonte csv         lê arquivos <tabela>.csv exportados dos marts (--pasta)

Exemplos:
  python bi/gerar_painel.py --fonte databricks --catalogo fea_academy --schema prod_marts
  python bi/gerar_painel.py --fonte csv --pasta exportacao_marts/
"""
from __future__ import annotations

import argparse
import base64
import gzip
import json
import os
from datetime import date, datetime, timezone
from pathlib import Path

import pandas as pd

TABELAS = [
    "fct_vendas",
    "dim_produtos",
    "dim_clientes",
    "dim_localidades",
    "dim_cartoes",
    "dim_motivos_venda",
    "brg_pedidos_motivos",
]

RAIZ = Path(__file__).resolve().parent
TEMPLATE = RAIZ / "painel_template.html"
PLOTLY = RAIZ / "vendor" / "plotly-basic.min.js"
DIA_ZERO = date(2011, 1, 1)


def ler_databricks(catalogo: str, schema: str) -> dict[str, pd.DataFrame]:
    from databricks import sql  # pip install databricks-sql-connector

    conexao = sql.connect(
        server_hostname=os.environ["DATABRICKS_SERVER_HOSTNAME"],
        http_path=os.environ["DATABRICKS_HTTP_PATH"],
        access_token=os.environ["DATABRICKS_TOKEN"],
    )
    tabelas = {}
    with conexao.cursor() as cursor:
        for tabela in TABELAS:
            cursor.execute(f"select * from {catalogo}.{schema}.{tabela}")
            tabelas[tabela] = cursor.fetchall_arrow().to_pandas()
    conexao.close()
    return tabelas


def ler_csv(pasta: Path) -> dict[str, pd.DataFrame]:
    # keep_default_na=False evita que o pandas transforme textos como "NA" (Namíbia) em nulo
    return {
        t: pd.read_csv(pasta / f"{t}.csv", keep_default_na=False, na_values=[""])
        for t in TABELAS
    }


def indexar(valores: pd.Series) -> tuple[list, pd.Series]:
    """Converte uma coluna em (lista de valores únicos ordenados, códigos inteiros)."""
    categorias = sorted(valores.astype(str).unique())
    mapa = {v: i for i, v in enumerate(categorias)}
    return categorias, valores.astype(str).map(mapa).astype(int)


def montar_payload(t: dict[str, pd.DataFrame], fonte: str) -> dict:
    f = t["fct_vendas"].copy()

    # Produtos
    produtos = t["dim_produtos"].set_index("pk_produto")
    ids_prod = sorted(f["fk_produto"].unique())
    pos_prod = {pid: i for i, pid in enumerate(ids_prod)}
    prod = produtos.loc[ids_prod]

    # Clientes
    clientes = t["dim_clientes"].set_index("pk_cliente")
    ids_cli = sorted(f["fk_cliente"].unique())
    pos_cli = {cid: i for i, cid in enumerate(ids_cli)}
    cli = clientes.loc[ids_cli]

    # Localidades (cidade + estado + país)
    loc = t["dim_localidades"].set_index("pk_localidade")
    trio = loc.loc[f["fk_localidade"], ["cidade", "estado", "pais"]].reset_index(drop=True)
    chave_local = trio["pais"].astype(str) + "|" + trio["estado"].astype(str) + "|" + trio["cidade"].astype(str)
    locais, cod_local = indexar(chave_local)

    # Cartões (tipo)
    cartoes = t["dim_cartoes"].set_index("pk_cartao")["tipo_cartao"]
    tipos_cartao, cod_cartao = indexar(cartoes.loc[f["fk_cartao"]].reset_index(drop=True))

    # Status
    status, cod_status = indexar(f["status_pedido"])

    # Motivos de venda: bitmask por pedido, a partir da tabela ponte
    motivos = t["dim_motivos_venda"].sort_values("pk_motivo_venda")
    motivos = pd.concat([motivos[motivos.pk_motivo_venda >= 0], motivos[motivos.pk_motivo_venda < 0]])
    bit = {mid: i for i, mid in enumerate(motivos["pk_motivo_venda"])}
    ponte = t["brg_pedidos_motivos"]
    mascara = (
        ponte.assign(b=ponte["fk_motivo_venda"].map(lambda m: 1 << bit[m]))
        .groupby("fk_pedido")["b"].sum()
    )
    pedidos = sorted(f["fk_pedido"].unique())
    pos_ped = {p: i for i, p in enumerate(pedidos)}

    # Descontos (poucos valores distintos)
    descontos, cod_desc = indexar(f["percentual_desconto"].round(4))

    dias = (pd.to_datetime(f["data_pedido"]).dt.date.map(lambda d: (d - DIA_ZERO).days)).astype(int)
    # valor bruto em décimos de milésimo (inteiro) para somar sem erro de arredondamento
    bruto = (pd.to_numeric(f["valor_bruto"]) * 10000).round().astype("int64")

    return {
        "meta": {
            "gerado_em": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
            "fonte": fonte,
            "linhas": int(len(f)),
            "dia_zero": DIA_ZERO.isoformat(),
        },
        "produtos": {
            "nome": prod["nome_produto"].astype(str).tolist(),
            "categoria": prod["categoria"].astype(str).tolist(),
            "subcategoria": prod["subcategoria"].astype(str).tolist(),
        },
        "clientes": {
            "nome": cli["nome_cliente"].astype(str).tolist(),
            "tipo": cli["tipo_cliente"].astype(str).tolist(),
        },
        "locais": [k.split("|") for k in locais],  # [pais, estado, cidade]
        "cartoes": tipos_cartao,
        "status": status,
        "motivos": motivos["nome_motivo_venda"].astype(str).tolist(),
        "descontos": [float(d) for d in descontos],
        "pedidos": {
            "id": [int(p) for p in pedidos],
            "motivos": [int(mascara.get(p, 0)) for p in pedidos],
        },
        "f": {
            "pedido": f["fk_pedido"].map(pos_ped).astype(int).tolist(),
            "produto": f["fk_produto"].map(pos_prod).astype(int).tolist(),
            "cliente": f["fk_cliente"].map(pos_cli).astype(int).tolist(),
            "local": cod_local.tolist(),
            "cartao": cod_cartao.tolist(),
            "status": cod_status.tolist(),
            "dia": dias.tolist(),
            "qtd": f["quantidade"].astype(int).tolist(),
            "bruto": bruto.tolist(),
            "desc": cod_desc.tolist(),
        },
    }


def gerar_html(payload: dict, destino: Path) -> None:
    dados = base64.b64encode(
        gzip.compress(json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8"), 9)
    ).decode("ascii")
    html = TEMPLATE.read_text(encoding="utf-8")
    html = html.replace("/*__PLOTLY__*/", PLOTLY.read_text(encoding="utf-8"))
    html = html.replace("__DADOS_GZIP_BASE64__", dados)
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(html, encoding="utf-8")
    print(f"Painel gerado em {destino} ({destino.stat().st_size / 1e6:.1f} MB, {payload['meta']['linhas']} linhas)")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--fonte", choices=["databricks", "csv"], required=True)
    p.add_argument("--catalogo", default="fea_academy")
    p.add_argument("--schema", default="prod_marts")
    p.add_argument("--pasta", type=Path, help="pasta com os CSVs dos marts (fonte csv)")
    p.add_argument("--saida", type=Path, default=RAIZ.parent / "docs" / "index.html")
    a = p.parse_args()

    if a.fonte == "databricks":
        tabelas = ler_databricks(a.catalogo, a.schema)
        fonte = f"Databricks · {a.catalogo}.{a.schema}"
    else:
        tabelas = ler_csv(a.pasta)
        fonte = "Exportação dos marts do dbt"
    gerar_html(montar_payload(tabelas, fonte), a.saida)


if __name__ == "__main__":
    main()
