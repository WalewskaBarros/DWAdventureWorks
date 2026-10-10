# Adventure Works – Data Warehouse de Vendas (Databricks + dbt)

Projeto do **Desafio de Certificação Analytics Engineer** da Indicium Academy.

A Adventure Works, fabricante de bicicletas, quer usar seus dados para tomar decisões comerciais.
Este repositório contém a camada de transformação (dbt) do data warehouse de **vendas**: lê os dados
brutos do ERP carregados no Databricks e entrega um esquema estrela documentado e testado para o
painel de BI.

## Arquitetura

```
Bitbucket (CSVs do ERP)
      │  notebook fea/databases_ingestion (pandas → Delta)
      ▼
Databricks · catálogo fea_academy · schema adventure_works   (dados brutos, 68 tabelas)
      │  dbt (dbt platform + adaptador dbt-databricks)
      ▼
staging  (14 views: tipos, nomes e limpeza)
      │
marts    (8 tabelas: fato, dimensões e ponte)
      │
      ▼
Power BI (painel interativo)
```

| Camada | Ferramenta |
|---|---|
| Extração e carga | Notebook da Indicium no Databricks Free Edition |
| Armazenamento | Databricks (Unity Catalog, SQL warehouse serverless) |
| Transformação | dbt platform (dbt Cloud) com `dbt-databricks` |
| Versionamento | GitHub (este repositório) |
| Visualização | Power BI |

## Modelagem (esquema estrela)

| Modelo | Tipo | Grão | Tabelas de origem |
|---|---|---|---|
| `fct_vendas` | Fato | 1 linha por item de pedido | salesorderdetail, salesorderheader |
| `dim_produtos` | Dimensão | Produto | product, productsubcategory, productcategory |
| `dim_clientes` | Dimensão | Cliente | customer, person, store |
| `dim_localidades` | Dimensão | Endereço (cidade, estado, país) | address, stateprovince, countryregion |
| `dim_cartoes` | Dimensão | Cartão de crédito | creditcard |
| `dim_motivos_venda` | Dimensão | Motivo de venda | salesreason |
| `brg_pedidos_motivos` | Ponte | Pedido × motivo | salesorderheadersalesreason |
| `dim_datas` | Dimensão | Dia (2011–2014) | gerada com `dbt_utils.date_spine` |

### Decisões de modelagem

- **Grão da fato no item do pedido.** É onde existem produto, quantidade, preço e desconto. O pedido
  fica na fato como dimensão degenerada (`fk_pedido`); número de pedidos = contagem distinta dele.
- **Motivo de venda em tabela ponte.** 4.482 pedidos têm mais de um motivo. Colocar o motivo na fato
  duplicaria itens e inflaria o faturamento; a ponte preserva o grão e permite filtrar por motivo.
- **Membro "Não informado" (-1)** em cartões e motivos, para nenhuma chave da fato ficar nula.
- **Cidade, estado e país pelo endereço de entrega** do pedido (`shiptoaddressid`).

### Métricas

| Métrica | Cálculo |
|---|---|
| Número de pedidos | contagem distinta de `fk_pedido` |
| Quantidade comprada | soma de `quantidade` |
| Valor total negociado | soma de `valor_bruto` = preço unitário × quantidade |
| Valor total negociado líquido | soma de `valor_liquido` = preço unitário × quantidade × (1 − desconto) |
| Ticket médio | (valor bruto − descontos) ÷ número de pedidos |

## Qualidade de dados

- **Testes de source:** `unique` e `not_null` nas chaves primárias das 14 tabelas de origem,
  `relationships` entre pedido, item, cliente, endereço e produto, e chave composta em
  pedido × motivo.
- **Testes nos marts:** `unique` e `not_null` em todas as chaves primárias, `relationships` de cada
  chave estrangeira da fato, `accepted_values`, `expression_is_true` (valor líquido ≤ valor bruto) e
  `equal_rowcount` (a fato tem exatamente as linhas da origem, sem duplicação).
- **Teste de dados pedido pelo CEO:** `tests/assert_vendas_brutas_2011.sql` garante que a venda bruta
  de 2011 é **$12.646.112,16**, valor auditado pela contabilidade.

### Problema encontrado na ingestão: Namíbia

O código ISO da Namíbia é `NA`. O notebook de ingestão lê os CSVs com pandas, que interpreta o texto
`NA` como valor ausente, e o país chega ao Databricks com código nulo. O teste de source detectou o
problema. Tratamento:

- `stg_erp__paises` restaura o código `NA`, e a chave da staging é testada com `unique` e `not_null`;
- o teste `not_null` da coluna na origem fica como **alerta (warn)**, documentado, para manter o
  problema visível na camada de origem.

### Resultado da última execução

| Comando | Resultado |
|---|---|
| `dbt run` | 22 modelos, todos com sucesso |
| `dbt test --select "source:*"` | 44 testes: 43 PASS, 1 WARN (Namíbia), 0 erros |
| `dbt test` | 92 testes: 91 PASS, 1 WARN (Namíbia), 0 erros |

## Estrutura do repositório

```
├── dbt_project.yml          configuração e materializações (staging = view, marts = table)
├── packages.yml             dbt_utils
├── macros/
│   ├── safe_int.sql         converte DOUBLE/NaN vindos do pandas em INT com segurança
│   └── agrega_texto.sql     concatena os motivos de venda de um pedido
├── models/
│   ├── staging/             _sources.yml, _stg_models.yml e 14 modelos stg_erp__*
│   └── marts/               _marts.yml, fato, dimensões e ponte
├── tests/
│   └── assert_vendas_brutas_2011.sql
└── analyses/
    └── resposta_4f_produto_promocao.sql
```

## Como executar

Pré-requisitos: o notebook `fea/databases_ingestion` do repositório
[indiciumtech/databricks-datasources](https://bitbucket.org/indiciumtech/databricks-datasources/src/main/)
executado no Databricks (cria `fea_academy.adventure_works`) e uma conexão do dbt com o SQL warehouse
apontando para o catálogo `fea_academy`.

```bash
dbt deps
dbt run
dbt test --select "source:*"
dbt test
dbt docs generate
```

Os modelos são criados nos schemas `<schema_do_alvo>_staging` e `<schema_do_alvo>_marts` dentro do
catálogo `fea_academy`. Credenciais (token, host, HTTP path) ficam na configuração do dbt, nunca neste
repositório.

## Pergunta 4-f

O produto com mais unidades compradas para o motivo de venda "On Promotion" é o
**Water Bottle - 30 oz.**, com 546 unidades (`analyses/resposta_4f_produto_promocao.sql`).
