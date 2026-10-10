-- Inclui um membro "Não informado" (-1) para pedidos sem cartão de crédito,
-- evitando chaves nulas na fato e linhas em branco no painel.
with cartoes as (
    select * from {{ ref('stg_erp__cartoes') }}
),

final as (
    select
        id_cartao                                                   as pk_cartao
        , tipo_cartao
    from cartoes

    union all

    select
        -1                                                          as pk_cartao
        , 'Não informado'                                           as tipo_cartao
)

select * from final
