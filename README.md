# Adventure Works – Data Warehouse com Databricks + dbt

Projeto do Desafio de Certificação Analytics Engineer (Indicium Academy).

## Arquitetura

```
Bitbucket (CSVs) ──► Notebook databases_ingestion ──► fea_academy.adventure_works (Delta, dados brutos)
                                                           │
                                         dbt (dbt platform + dbt-databricks)
                                                           │
                         staging (views)  ──►  marts (tabelas: fato, dimensões, ponte)
                                                           │
                                                      Power BI
```

## Modelagem (esquema estrela)

| Modelo | Grão | Origem |
|---|---|---|
| `fct_vendas` | item de pedido | salesorderdetail + salesorderheader |
| `dim_produtos` | produto | product, productsubcategory, productcategory |
| `dim_clientes` | cliente | customer, person, store |
| `dim_localidades` | endereço (cidade/estado/país) | address, stateprovince, countryregion |
| `dim_cartoes` | cartão de crédito | creditcard |
| `dim_motivos_venda` | motivo de venda | salesreason |
| `brg_pedidos_motivos` | pedido x motivo | salesorderheadersalesreason |
| `dim_datas` | dia | gerada com `dbt_utils.date_spine` |

Um pedido pode ter mais de um motivo de venda. Por isso os motivos ficam numa tabela ponte
(`brg_pedidos_motivos`) e não na fato: assim a fato mantém o grão de item e as métricas não duplicam.

## Testes

* **Sources:** `unique`/`not_null` nas chaves primárias e `relationships` entre as tabelas de venda.
* **Marts:** `unique`/`not_null` em todas as chaves primárias, `relationships` das FKs da fato,
  `accepted_values`, `expression_is_true` e `equal_rowcount` (fato x origem).
* **Teste de dados:** `tests/assert_vendas_brutas_2011.sql` garante que a venda bruta de 2011 é
  **$12.646.112,16**, valor auditado pela contabilidade.

## Como rodar

```bash
dbt deps
dbt run
dbt test --select "source:*"
dbt test
dbt docs generate
```

## Métricas

| Métrica | Cálculo |
|---|---|
| Número de pedidos | contagem distinta de `fk_pedido` |
| Quantidade comprada | soma de `quantidade` |
| Valor total negociado | soma de `valor_bruto` (preço unitário × quantidade) |
| Valor total negociado líquido | soma de `valor_liquido` (preço × quantidade × (1 − desconto)) |
| Ticket médio | valor líquido ÷ número de pedidos |
