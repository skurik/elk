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
    'IIS_iQube_PUT_Translation_Verification_99pctl_Response_Time_2d',
    'IIS_iQube_PUT_Translation_Verification_99pctl_Response_Time_1mo',
    'IIS_iQube_PUT_Translation_Verification_99pctl_Response_Time_1h',
    'IIS_TC_GET_Project_99pctl_Response_Time_2d',
    'IIS_TC_GET_Project_Page_Input_99pctl_Response_Time_2d',
    'IIS_iQube_GET_Project_99pctl_Response_Time_2d',
    'IIS_iQube_PUT_Translation_And_Verification_Request_Count_1h',
    'IIS_iQube_PUT_Translation_And_Verification_Request_Count_2d',
    'IIS_iQube_PUT_Translation_And_Verification_Request_Count_1mo',
    'IIS_iQube_PUT_Translation_And_Verification_And_GET_Segment_Request_Count_1h',
    'IIS_iQube_PUT_Translation_And_Verification_And_GET_Segment_Request_Count_2d',
    'IIS_iQube_PUT_Translation_And_Verification_And_GET_Segment_Request_Count_1mo' ] %}

{% set dashboards = [ 'Web_Response_Times_2d' ] %}
{% set searches = [
    'iQube_PUT_Assignment_options',
    'iQube_PUT_Segment_Confirmation',
    'iQube_Status_gte_500',
    'iQube_GET_Project' ] %}

http://{{ opts.ip_address }}:9200/_template/template_log_iis:
  http.query:
    - method: PUT
    - data_file: /srv/share/config/elasticsearch/log_template.json
    - status: 200
    - match: 'acknowledged"\s*:\s*true'
    - match_type: pcre

# Create visualizations
#
# If creating a visualization using http.query fails (as it currently does for IIS_iQube_PUT_Translation_And_Verification_Request_Count_2d), issue the following command manually:
# curl -X POST -d @/srv/share/IIS_iQube_PUT_Translation_And_Verification_Request_Count_2d.json http://10.0.2.15:9200/.kibana/visualization/IIS_iQube_PUT_Translation_And_Verification_Request_Count_2d --header "Content-Type:application/json"
# curl -X POST -d @/srv/share/config/kibana/visualizations/IIS_iQube_PUT_Translation_And_Verification_And_GET_Segment_Request_Count_1mo.json http://10.0.2.15:9200/.kibana/visualization/IIS_iQube_PUT_Translation_And_Verification_And_GET_Segment_1mo --header "Content-Type:application/json"

#
# For some reason, the http.query module probably does not like spaces in the JSON file
#
# UPDATE: If we remove all tabs and newlines from the 'visState' element content, http.query is happy
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

# Create dashboards
#
{% for db in dashboards %}

http://{{ opts.ip_address }}:9200/.kibana/dashboard/{{ db }}:
  http.query:
    - method: POST
    - data_file: /srv/share/config/kibana/dashboards/{{ db }}.json
    - status: 201
    - match: 'result"\s*:\s*"created"'
    - match_type: pcre

{% endfor %}

# Create searches
#
{% for s in searches %}

http://{{ opts.ip_address }}:9200/.kibana/search/{{ s }}:
  http.query:
    - method: POST
    - data_file: /srv/share/config/kibana/searches/{{ s }}.json
    - status: 201
    - match: 'result"\s*:\s*"created"'
    - match_type: pcre

{% endfor %}