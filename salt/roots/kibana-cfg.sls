{% import 'options.sls' as opts %}
{% set visualizations = [
    'IIS_iQube_Avg_Response_Time_2d',
    'IIS_iQube_Avg_Response_Time_1mo',
    'IIS_TC_Avg_Response_Time_2d',
    'IIS_TC_Avg_Response_Time_1mo',
    'CPU_iQube_DB_Avg_IOWait_Pct_2d',
    'CPU_iQube_DB_Avg_User_Time_Pct_2d',
    'CPU_iQube_Webserver_Avg_IOWait_Pct_2d',
    'CPU_iQube_Webserver_Avg_User_Time_Pct_2d',
    'IIS_iQube_TC_Avg_Response_Time_2d',
    'IIS_iQube_TC_Avg_Response_Time_1mo',
    'IIS_iQube_PUT_Translation_Avg_Response_Time_2d',
    'IIS_iQube_PUT_Verification_Avg_Response_Time_2d',
    'IIS_iQube_PUT_Translation_99pctl_Response_Time_2d',
    'IIS_iQube_PUT_Verification_99pctl_Response_Time_2d',
    'IIS_iQube_PUT_Translation_Verification_99pctl_Response_Time_2d' ] %}

http://{{ opts.ip_address }}:9200/_template/template_log_iis:
  http.query:
    - method: PUT
    - data_file: /srv/share/config/elasticsearch/log_template.json
    - status: 200
    - match: 'acknowledged"\s*:\s*true'
    - match_type: pcre

# Create visualizations
#
{% for vis in visualizations %}

http://{{ opts.ip_address }}:9200/.kibana/visualization/{{ vis }}:
  http.query:
    - method: POST
    - data_file: /srv/share/config/kibana/visualizations/{{ vis }}.json
    - status: 201
    - match: 'result"\s*:\s*"created"'
    - match_type: pcre

{% endfor %}