with source as (
    select * from {{ source('erp_adventure_works', 'sales_salesorderdetail') }}
),

renamed as (
    select
        cast(salesorderdetailid as int)                    as id_item_pedido
        , cast(salesorderid as int)                        as id_pedido
        , cast(productid as int)                           as id_produto
        , cast(specialofferid as int)                      as id_oferta_especial
        , cast(orderqty as int)                            as quantidade
        , cast(unitprice as decimal(18, 4))                as preco_unitario
        , cast(unitpricediscount as decimal(18, 4))        as percentual_desconto
    from source
)

select * from renamed
