with source as (
    select * from {{ source('erp_adventure_works', 'production_product') }}
),

renamed as (
    select
        cast(productid as int)                             as id_produto
        , trim(name)                                       as nome_produto
        , trim(productnumber)                              as codigo_produto
        , trim(color)                                      as cor
        , trim(productline)                                as linha_produto
        , {{ safe_int('productsubcategoryid') }}           as id_subcategoria
        , cast(standardcost as decimal(18, 4))             as custo_padrao
        , cast(listprice as decimal(18, 4))                as preco_lista
    from source
)

select * from renamed
