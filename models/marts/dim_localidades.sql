-- Uma linha por endereço. A fato usa o endereço de entrega (shiptoaddressid) do pedido.
with enderecos as (
    select * from {{ ref('stg_erp__enderecos') }}
),

estados as (
    select * from {{ ref('stg_erp__estados') }}
),

paises as (
    select * from {{ ref('stg_erp__paises') }}
),

final as (
    select
        enderecos.id_endereco                                       as pk_localidade
        , enderecos.cidade
        , estados.nome_estado                                       as estado
        , estados.sigla_estado
        , paises.nome_pais                                          as pais
        , paises.codigo_pais
        , enderecos.codigo_postal
    from enderecos
    left join estados on enderecos.id_estado = estados.id_estado
    left join paises on estados.codigo_pais = paises.codigo_pais
)

select * from final
