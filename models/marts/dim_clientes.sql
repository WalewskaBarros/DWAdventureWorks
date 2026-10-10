with clientes as (
    select * from {{ ref('stg_erp__clientes') }}
),

pessoas as (
    select * from {{ ref('stg_erp__pessoas') }}
),

lojas as (
    select * from {{ ref('stg_erp__lojas') }}
),

final as (
    select
        clientes.id_cliente                                         as pk_cliente
        , coalesce(pessoas.nome_completo, lojas.nome_loja)          as nome_cliente
        , lojas.nome_loja
        , case
            when clientes.id_loja is not null then 'Loja revendedora'
            else 'Pessoa física'
          end                                                       as tipo_cliente
        , clientes.id_territorio
    from clientes
    left join pessoas on clientes.id_pessoa = pessoas.id_pessoa
    left join lojas on clientes.id_loja = lojas.id_loja
)

select * from final
