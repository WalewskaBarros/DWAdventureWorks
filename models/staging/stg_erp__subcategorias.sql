with source as (
    select * from {{ source('erp_adventure_works', 'production_productsubcategory') }}
),

renamed as (
    select
        cast(productsubcategoryid as int)                  as id_subcategoria
        , cast(productcategoryid as int)                   as id_categoria
        , trim(name)                                       as nome_subcategoria
    from source
)

select * from renamed
