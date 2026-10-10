with produtos as (
    select * from {{ ref('stg_erp__produtos') }}
),

subcategorias as (
    select * from {{ ref('stg_erp__subcategorias') }}
),

categorias as (
    select * from {{ ref('stg_erp__categorias') }}
),

final as (
    select
        produtos.id_produto                                         as pk_produto
        , produtos.nome_produto
        , produtos.codigo_produto
        , coalesce(produtos.cor, 'Sem cor')                         as cor
        , coalesce(subcategorias.nome_subcategoria, 'Sem subcategoria') as subcategoria
        , coalesce(categorias.nome_categoria, 'Sem categoria')      as categoria
        , produtos.custo_padrao
        , produtos.preco_lista
    from produtos
    left join subcategorias on produtos.id_subcategoria = subcategorias.id_subcategoria
    left join categorias on subcategorias.id_categoria = categorias.id_categoria
)

select * from final
