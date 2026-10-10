-- Grão: um registro por item de pedido de venda (salesorderdetail).
with itens as (
    select * from {{ ref('stg_erp__pedidos_itens') }}
),

pedidos as (
    select * from {{ ref('stg_erp__pedidos') }}
),

pedidos_motivos as (
    select * from {{ ref('stg_erp__pedidos_motivos') }}
),

motivos as (
    select * from {{ ref('stg_erp__motivos_venda') }}
),

-- Texto com todos os motivos do pedido, só para exibição/leitura.
-- Para filtrar por motivo use dim_motivos_venda + brg_pedidos_motivos.
motivos_por_pedido as (
    select
        pedidos_motivos.id_pedido
        , {{ agrega_texto('motivos.nome_motivo_venda') }}           as motivos_venda
    from pedidos_motivos
    inner join motivos on pedidos_motivos.id_motivo_venda = motivos.id_motivo_venda
    group by pedidos_motivos.id_pedido
),

joined as (
    select
        {{ dbt_utils.generate_surrogate_key(['itens.id_pedido', 'itens.id_item_pedido']) }} as sk_venda
        , itens.id_item_pedido
        , itens.id_pedido                                           as fk_pedido
        , pedidos.numero_pedido
        , itens.id_produto                                          as fk_produto
        , pedidos.id_cliente                                        as fk_cliente
        , pedidos.id_endereco_entrega                               as fk_localidade
        , coalesce(pedidos.id_cartao, -1)                           as fk_cartao
        , pedidos.data_pedido                                       as fk_data
        , pedidos.data_pedido
        , pedidos.data_envio
        , pedidos.status_pedido
        , pedidos.is_pedido_online
        , coalesce(motivos_por_pedido.motivos_venda, 'Não informado') as motivos_venda
        , itens.quantidade
        , itens.preco_unitario
        , itens.percentual_desconto
    from itens
    inner join pedidos on itens.id_pedido = pedidos.id_pedido
    left join motivos_por_pedido on itens.id_pedido = motivos_por_pedido.id_pedido
),

metricas as (
    select
        *
        , cast(quantidade * preco_unitario as decimal(18, 4))                              as valor_bruto
        , cast(quantidade * preco_unitario * percentual_desconto as decimal(18, 4))        as valor_desconto
        , cast(quantidade * preco_unitario * (1 - percentual_desconto) as decimal(18, 4))  as valor_liquido
    from joined
)

select * from metricas
