-- Tabela ponte (bridge) entre pedido e motivo de venda.
-- Um pedido pode ter vários motivos; manter essa relação fora da fato evita
-- duplicar os itens de venda (fan-out) e distorcer as métricas.
with pedidos as (
    select id_pedido from {{ ref('stg_erp__pedidos') }}
),

pedidos_motivos as (
    select * from {{ ref('stg_erp__pedidos_motivos') }}
),

final as (
    select
        pedidos.id_pedido                                           as fk_pedido
        , coalesce(pedidos_motivos.id_motivo_venda, -1)             as fk_motivo_venda
    from pedidos
    left join pedidos_motivos on pedidos.id_pedido = pedidos_motivos.id_pedido
)

select
    {{ dbt_utils.generate_surrogate_key(['fk_pedido', 'fk_motivo_venda']) }} as sk_pedido_motivo
    , *
from final
