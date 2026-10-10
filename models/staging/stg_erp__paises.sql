-- O código ISO da Namíbia é "NA". O notebook de ingestão lê os CSVs com pandas,
-- que interpreta o texto "NA" como valor ausente; por isso o código chega nulo.
-- Aqui o valor é restaurado para não perder o país nas análises.
with source as (
    select * from {{ source('erp_adventure_works', 'person_countryregion') }}
),

renamed as (
    select
        case
            when countryregioncode is null and trim(name) = 'Namibia' then 'NA'
            else trim(countryregioncode)
        end                                                as codigo_pais
        , trim(name)                                       as nome_pais
    from source
)

select * from renamed
