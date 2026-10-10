with source as (
    select * from {{ source('erp_adventure_works', 'sales_creditcard') }}
),

renamed as (
    select
        cast(creditcardid as int)                          as id_cartao
        , trim(cardtype)                                   as tipo_cartao
    from source
)

select * from renamed
