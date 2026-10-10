with source as (
    select * from {{ source('erp_adventure_works', 'sales_store') }}
),

renamed as (
    select
        cast(businessentityid as int)                      as id_loja
        , trim(name)                                       as nome_loja
    from source
)

select * from renamed
