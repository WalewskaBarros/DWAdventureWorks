-- Teste de dados pedido pelo CEO (Carlos Silveira):
-- a venda bruta (soma de preco_unitario * quantidade) em 2011, auditada pela contabilidade,
-- é de $12.646.112,16. O teste falha (retorna linha) se o valor calculado for diferente.
with vendas_2011 as (
    select round(sum(valor_bruto), 2) as venda_bruta_2011
    from {{ ref('fct_vendas') }}
    where year(data_pedido) = 2011
)

select *
from vendas_2011
where venda_bruta_2011 is null
   or venda_bruta_2011 <> 12646112.16
