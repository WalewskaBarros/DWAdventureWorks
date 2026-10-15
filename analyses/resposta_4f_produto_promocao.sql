-- Pergunta 4-f: qual produto tem a maior quantidade de unidades compradas
-- para o motivo de venda "On Promotion" (tipo Promotion)?

select
    produtos.nome_produto
    , sum(vendas.quantidade) as unidades_compradas
from {{ ref('fct_vendas') }} as vendas
inner join {{ ref('brg_pedidos_motivos') }} as ponte
    on vendas.fk_pedido = ponte.fk_pedido
inner join {{ ref('dim_motivos_venda') }} as motivos
    on ponte.fk_motivo_venda = motivos.pk_motivo_venda
inner join {{ ref('dim_produtos') }} as produtos
    on vendas.fk_produto = produtos.pk_produto
where motivos.nome_motivo_venda = 'On Promotion'
group by produtos.nome_produto
order by unidades_compradas desc
limit 5
