{% macro ga4_param(key, value_type='string') %}
    (select ep.value.{{ value_type }}_value from unnest(event_params) as ep where ep.key = '{{ key }}')
{% endmacro %}