with source as (
    select * from {{ source('erp_adventure_works', 'production_productcategory') }}
),

renamed as (
    select
        cast(productcategoryid as int)                     as id_categoria
        , trim(name)                                       as nome_categoria
    from source
)

select * from renamed
