with vendas_2011 as (
    select round(sum(valor_bruto), 2) as venda_bruta_2011
    from {{ ref('fct_vendas') }}
    where year(data_pedido) = 2011
)

select *
from vendas_2011
where venda_bruta_2011 is null
   or venda_bruta_2011 <> 12646112.16
