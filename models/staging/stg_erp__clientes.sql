with source as (
    select * from {{ source('erp_adventure_works', 'sales_customer') }}
),

renamed as (
    select
        cast(customerid as int)                            as id_cliente
        , {{ safe_int('personid') }}                       as id_pessoa
        , {{ safe_int('storeid') }}                        as id_loja
        , cast(territoryid as int)                         as id_territorio
    from source
)

select * from renamed
