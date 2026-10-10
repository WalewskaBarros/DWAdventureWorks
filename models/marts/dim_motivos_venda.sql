-- Inclui um membro "Não informado" (-1) para pedidos sem motivo de venda registrado.
with motivos as (
    select * from {{ ref('stg_erp__motivos_venda') }}
),

final as (
    select
        id_motivo_venda                                             as pk_motivo_venda
        , nome_motivo_venda
        , tipo_motivo_venda
    from motivos

    union all

    select
        -1                                                          as pk_motivo_venda
        , 'Não informado'                                           as nome_motivo_venda
        , 'Não informado'                                           as tipo_motivo_venda
)

select * from final
