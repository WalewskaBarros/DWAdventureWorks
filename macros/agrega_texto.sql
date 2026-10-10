{#- Concatena valores distintos de uma coluna em ordem alfabética, separados por vírgula.
    Implementação específica por adaptador (Databricks em produção; DuckDB só para testes locais). -#}
{% macro agrega_texto(column) -%}
    {%- if target.type == 'databricks' -%}
        array_join(array_sort(collect_set({{ column }})), ', ')
    {%- else -%}
        string_agg(distinct {{ column }}, ', ' order by {{ column }})
    {%- endif -%}
{%- endmacro %}
