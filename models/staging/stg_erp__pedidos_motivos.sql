with source as (
    select * from {{ source('erp_adventure_works', 'sales_salesorderheadersalesreason') }}
),

renamed as (
    select
        cast(salesorderid as int)                          as id_pedido
        , cast(salesreasonid as int)                       as id_motivo_venda
    from source
)

select * from renamed
