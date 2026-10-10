with source as (
    select * from {{ source('erp_adventure_works', 'person_address') }}
),

renamed as (
    select
        cast(addressid as int)                             as id_endereco
        , trim(addressline1)                               as logradouro
        , trim(city)                                       as cidade
        , cast(stateprovinceid as int)                     as id_estado
        , trim(cast(postalcode as string))                 as codigo_postal
    from source
)

select * from renamed
