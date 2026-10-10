with source as (
    select * from {{ source('erp_adventure_works', 'sales_salesorderheader') }}
),

renamed as (
    select
        cast(salesorderid as int)                          as id_pedido
        , concat('SO', cast(salesorderid as string))      as numero_pedido
        , cast(orderdate as date)                          as data_pedido
        , cast(duedate as date)                            as data_vencimento
        , cast(shipdate as date)                           as data_envio
        , cast(status as int)                              as codigo_status
        , case cast(status as int)
            when 1 then 'Em processamento'
            when 2 then 'Aprovado'
            when 3 then 'Em espera'
            when 4 then 'Rejeitado'
            when 5 then 'Enviado'
            when 6 then 'Cancelado'
            else 'Desconhecido'
          end                                              as status_pedido
        , cast(onlineorderflag as boolean)                 as is_pedido_online
        , cast(customerid as int)                          as id_cliente
        , {{ safe_int('salespersonid') }}                  as id_vendedor
        , cast(territoryid as int)                         as id_territorio
        , cast(billtoaddressid as int)                     as id_endereco_cobranca
        , cast(shiptoaddressid as int)                     as id_endereco_entrega
        , cast(shipmethodid as int)                        as id_metodo_envio
        , {{ safe_int('creditcardid') }}                   as id_cartao
        , cast(subtotal as decimal(18, 4))                 as subtotal
        , cast(taxamt as decimal(18, 4))                   as valor_imposto
        , cast(freight as decimal(18, 4))                  as valor_frete
        , cast(totaldue as decimal(18, 4))                 as valor_total_devido
    from source
)

select * from renamed
