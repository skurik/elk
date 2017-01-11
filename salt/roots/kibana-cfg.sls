{% import 'options.sls' as opts %}
{% set ip_address = salt['grains.get']('ip4_interfaces:eth0')[0] %}
{% set visualizations = [ 'IIS_iQube_Avg_Response_Time_2d', 'IIS_iQube_Avg_Response_Time_1mo', 'IIS_TC_Avg_Response_Time_2d', 'IIS_TC_Avg_Response_Time_1mo', 'CPU_iQube_DB_Avg_IOWait_Pct_2d', 'CPU_iQube_DB_Avg_User_Time_Pct_2d', 'CPU_iQube_Webserver_Avg_IOWait_Pct_2d', 'CPU_iQube_Webserver_Avg_User_Time_Pct_2d', 'IIS_iQube_TC_Avg_Response_Time_2d', 'IIS_iQube_TC_Avg_Response_Time_1mo' ] %}

http://{{ ip_address }}:9200/_template/template_log_iis:
  http.query:
    - method: PUT
    - data_file: /srv/share/config/elasticsearch/log_template.json
    - status: 200
    - match: 'acknowledged"\s*:\s*true'
    - match_type: pcre

# Create visualizations
#
{% for vis in visualizations %}

http://{{ ip_address }}:9200/.kibana/visualization/{{ vis }}:
  http.query:
    - method: POST
    - data_file: /srv/share/config/kibana/visualizations/{{ vis }}.json
    - status: 201
    - match: 'result"\s*:\s*"created"'
    - match_type: pcre

{% endfor %}