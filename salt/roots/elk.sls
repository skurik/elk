{% import 'options.sls' as opts %}

# The second item specifies whether the service is managed by the System-V init scripts ('1') or not
#
{% set elk_services = [ ['elasticsearch', 1], ['kibana', 1], ['logstash', 0], ['filebeat', 1], ['metricbeat', 1] ] %}
{% set ip_address = salt['grains.get']('ip4_interfaces:eth0')[0] %}
{% set visualizations = [ 'IIS_iQube_Avg_Response_Time_2d', 'IIS_iQube_Avg_Response_Time_1mo', 'IIS_TC_Avg_Response_Time_2d', 'IIS_TC_Avg_Response_Time_1mo', 'CPU_iQube_DB_Avg_IOWait_Pct_2d', 'CPU_iQube_DB_Avg_User_Time_Pct_2d', 'CPU_iQube_Webserver_Avg_IOWait_Pct_2d', 'CPU_iQube_Webserver_Avg_User_Time_Pct_2d', 'IIS_iQube_TC_Avg_Response_Time_2d' ] %}

es_import_pgp_key:
  cmd.run:
    - name: 'wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -'

apt_transport_https:
  pkg.installed:
    - name: apt-transport-https

add_elastic_repository:
  cmd.run:
    - name: 'echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list'

apt_update:
  cmd.run:
    - name: 'apt-get update'

install_elk_services:
  pkg.installed:
    - pkgs:
      {% for service in elk_services %}
      - {{ service[0] }}
      {% endfor %}

# DEBUG state
#
# write_ip_to_file:
#   cmd.run:
#     - name: 'echo {{ ip_address }} > /root/ip'

es_listen_on_ethernet_iface:
  file.replace:
    - name: "/etc/elasticsearch/elasticsearch.yml"
    - pattern: "^\\s*#\\s*network\\.host:\\s*.*"
    - repl: "network.host: {{ ip_address }}"
    - backup: False

# DEBUG state (use data directory on a drive where we will not run out of space)
#
es_use_data_dir_on_large_drive:
  file.replace:
    - name: "/etc/elasticsearch/elasticsearch.yml"
    - pattern: "^\\s*#\\s*path\\.data:\\s*.*"
    - repl: "path.data: {{ opts.es_data_dir }}"
    - backup: False

kibana_listen_on_ethernet_iface:
  file.replace: 
    - name: "/etc/kibana/kibana.yml"
    - pattern: "^\\s*#\\s*server\\.host:\\s*.*"
    - repl: 'server.host: "{{ ip_address }}"'
    - backup: False

kibana_set_elasticsearch_url:
  file.replace:
    - name: "/etc/kibana/kibana.yml"
    - pattern: "^\\s*#\\s*elasticsearch\\.url:\\s*.*"
    - repl: 'elasticsearch.url: "http://{{ ip_address }}:9200"'
    - backup: False

logstash_main_config_reload_automatic:
  file.replace:
    - name: "/etc/logstash/logstash.yml"
    - pattern: "^\\s*#?\\s*config\\.reload\\.automatic:\\s*.*"
    - repl: 'config.reload.automatic: true'
    - backup: False

logstash_main_config_reload_interval:
  file.replace:
    - name: "/etc/logstash/logstash.yml"
    - pattern: "^\\s*#?\\s*config\\.reload\\.interval:\\s*.*"
    - repl: 'config.reload.interval: 3'
    - backup: False

logstash_pipeline_config:
  file.managed:
    - name: "/etc/logstash/conf.d/logstash.conf"
    - source: "/srv/share/config/logstash/conf.d/logstash.conf"

logstash_pipeline_config_elasticsearch_host:
  file.replace:
    - name: "/etc/logstash/conf.d/logstash.conf"
    - pattern: "___ELASTICSEARCH_HOST___"
    - repl: '{{ ip_address }}'
    - backup: False

filebeat_config_template:
  file.managed:
    - name: "/etc/filebeat/filebeat.yml"
    - source: "/srv/share/config/filebeat/filebeat.yml"

filebeat_config_iis_iqube_path:
  file.replace:
    - name: "/etc/filebeat/filebeat.yml"
    - pattern: "___LOG_DIR_IIS_IQUBE___"
    - repl: '{{ opts.iqube_iis_log_dir }}'
    - backup: False

filebeat_config_iis_tc_path:
  file.replace:
    - name: "/etc/filebeat/filebeat.yml"
    - pattern: "___LOG_DIR_IIS_TC___"
    - repl: '{{ opts.tc_iis_log_dir }}'
    - backup: False

filebeat_config_logstash_host:
  file.replace:
    - name: "/etc/filebeat/filebeat.yml"
    - pattern: "___LOGSTASH_HOST___"
    - repl: '{{ opts.logstash_host }}'
    - backup: False

metricbeat_config_template:
  file.managed:
    - name: "/etc/metricbeat/metricbeat.yml"
    - source: "/srv/share/config/metricbeat/metricbeat.yml"

metricbeat_config_logstash_host:
  file.replace:
    - name: "/etc/metricbeat/metricbeat.yml"
    - pattern: "___LOGSTASH_HOST___"
    - repl: '{{ opts.logstash_host }}'
    - backup: False

/var/log/iis/iqube:
  file.directory: []

/var/log/iis/tc:
  file.directory: []

# Once we move to Ubuntu 16.04, this might need to change (systemd will be used instead of System V)
#
# TODO: Move this command to options
{% for service in elk_services %}
  {% if service[1] == 1 %}

run_{{ service[0] }}_on_startup:
  cmd.run:
    - name: 'update-rc.d {{ service[0] }} defaults 95 10'

  {% endif %}

{{ service[0] }}:
  service.running: []  

{% endfor %}

# http://{{ ip_address }}:9200/_template/template_log_iis:
#   http.query:
#     - method: PUT
#     - data_file: /srv/share/config/elasticsearch/log_template.json
#     - status: 200
#     - match: 'acknowledged"\s*:\s*true'
#     - match_type: pcre

# # Create visualizations
# #
# {% for vis in visualizations %}

# http://{{ ip_address }}:9200/.kibana/visualization/{{ vis }}:
#   http.query:
#     - method: POST
#     - data_file: /srv/share/config/kibana/visualizations/{{ vis }}.json
#     - status: 201
#     - match: 'result"\s*:\s*"created"'
#     - match_type: pcre

# {% endfor %}

# # IIS\iQube\Avg. response time (last 2 days)
# # TODO: Add filter to only consider iQube logs
# http://{{ ip_address }}:9200/.kibana/visualization/IIS_iQube_Avg_Response_Time_2d:
#   http.query:
#     - method: POST
#     - data_file: /srv/share/config/kibana/visualizations/IIS_iQube_Avg_Response_Time_2d.json
#     - status: 201
#     - match: 'result"\s*:\s*"created"'
#     - match_type: pcre

# # IIS\iQube\Avg. response time (last 1 month)
# # TODO: Add filter to only consider iQube logs
# http://{{ ip_address }}:9200/.kibana/visualization/IIS_iQube_Avg_Response_Time_1mo:
#   http.query:
#     - method: POST
#     - data_file: /srv/share/config/kibana/visualizations/IIS_iQube_Avg_Response_Time_1mo.json
#     - status: 201
#     - match: 'result"\s*:\s*"created"'
#     - match_type: pcre

# #####################################
# # iQube Webserver ###################
# #####################################

# # CPU\iQube webserver\User time pct. (last 2 days)
# # TODO: Add filter to only consider metrics from the iQube webserver
# http://{{ ip_address }}:9200/.kibana/visualization/CPU_iQube_Webserver_Avg_User_Time_Pct_2d:
#   http.query:
#     - method: POST
#     - data_file: /srv/share/config/kibana/visualizations/CPU_iQube_Webserver_Avg_User_Time_Pct_2d.json
#     - status: 201
#     - match: 'result"\s*:\s*"created"'
#     - match_type: pcre

# # CPU\iQube webserver\I/O wait time pct. (last 2 days)
# # TODO: Add filter to only consider metrics from the iQube webserver
# http://{{ ip_address }}:9200/.kibana/visualization/CPU_iQube_Webserver_Avg_IOWait_Pct_2d:
#   http.query:
#     - method: POST
#     - data_file: /srv/share/config/kibana/visualizations/CPU_iQube_Webserver_Avg_IOWait_Pct_2d.json
#     - status: 201
#     - match: 'result"\s*:\s*"created"'
#     - match_type: pcre


# #####################################
# # iQube DB server ###################
# #####################################

# # CPU\iQube DB\User time pct. (last 2 days)
# # TODO: Add filter to only consider metrics from the iQube DB server
# http://{{ ip_address }}:9200/.kibana/visualization/CPU_iQube_DB_Avg_User_Time_Pct_2d:
#   http.query:
#     - method: POST
#     - data_file: /srv/share/config/kibana/visualizations/CPU_iQube_DB_Avg_User_Time_Pct_2d.json
#     - status: 201
#     - match: 'result"\s*:\s*"created"'
#     - match_type: pcre

# # CPU\iQube webserver\I/O wait time pct. (last 2 days)
# # TODO: Add filter to only consider metrics from the iQube DB server
# http://{{ ip_address }}:9200/.kibana/visualization/CPU_iQube_DB_Avg_IOWait_Pct_2d:
#   http.query:
#     - method: POST
#     - data_file: /srv/share/config/kibana/visualizations/CPU_iQube_DB_Avg_IOWait_Pct_2d.json
#     - status: 201
#     - match: 'result"\s*:\s*"created"'
#     - match_type: pcre  