with source as (
    select * from {{ source('erp_adventure_works', 'person_stateprovince') }}
),

renamed as (
    select
        cast(stateprovinceid as int)                       as id_estado
        , trim(stateprovincecode)                          as sigla_estado
        , trim(countryregioncode)                          as codigo_pais
        , trim(name)                                       as nome_estado
        , cast(territoryid as int)                         as id_territorio
    from source
)

select * from renamed
