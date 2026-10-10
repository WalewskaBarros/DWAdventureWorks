{#-
  O notebook de ingestão lê os CSVs com pandas. Colunas inteiras que possuem nulos
  (ex.: customer.storeid, salesorderheader.creditcardid) chegam ao Delta como DOUBLE
  e, dependendo da conversão, podem conter NaN. Um cast direto de NaN para INT
  vira 0 no Spark, o que quebraria joins e testes. Esta macro trata os dois casos.
-#}
{% macro safe_int(column) -%}
    case
        when {{ column }} is null then null
        when isnan(cast({{ column }} as double)) then null
        else cast({{ column }} as int)
    end
{%- endmacro %}
