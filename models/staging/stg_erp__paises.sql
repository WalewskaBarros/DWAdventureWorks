with source as (
    select * from {{ source('erp_adventure_works', 'person_countryregion') }}
),

renamed as (
    select
        trim(countryregioncode)                            as codigo_pais
        , trim(name)                                       as nome_pais
    from source
)

select * from renamed
