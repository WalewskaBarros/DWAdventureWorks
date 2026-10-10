with datas as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2011-01-01' as date)",
        end_date="cast('2015-01-01' as date)"
    ) }}
),

final as (
    select
        cast(date_day as date)                                      as pk_data
        , year(date_day)                                            as ano
        , quarter(date_day)                                         as trimestre
        , month(date_day)                                           as mes
        , case month(date_day)
            when 1 then 'Janeiro' when 2 then 'Fevereiro' when 3 then 'Março'
            when 4 then 'Abril' when 5 then 'Maio' when 6 then 'Junho'
            when 7 then 'Julho' when 8 then 'Agosto' when 9 then 'Setembro'
            when 10 then 'Outubro' when 11 then 'Novembro' when 12 then 'Dezembro'
          end                                                       as nome_mes
        , year(date_day) * 100 + month(date_day)                    as ano_mes
        , day(date_day)                                             as dia
    from datas
)

select * from final
