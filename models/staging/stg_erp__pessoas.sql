with source as (
    select * from {{ source('erp_adventure_works', 'person_person') }}
),

renamed as (
    select
        cast(businessentityid as int)                      as id_pessoa
        , trim(persontype)                                 as tipo_pessoa
        , trim(firstname)                                  as primeiro_nome
        , trim(middlename)                                 as nome_do_meio
        , trim(lastname)                                   as sobrenome
        , concat_ws(' ', trim(firstname), trim(middlename), trim(lastname)) as nome_completo
    from source
)

select * from renamed
