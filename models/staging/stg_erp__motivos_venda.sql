with source as (
    select * from {{ source('erp_adventure_works', 'sales_salesreason') }}
),

renamed as (
    select
        cast(salesreasonid as int)                         as id_motivo_venda
        , trim(name)                                       as nome_motivo_venda
        , trim(reasontype)                                 as tipo_motivo_venda
    from source
)

select * from renamed
