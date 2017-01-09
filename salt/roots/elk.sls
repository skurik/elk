# The second item specifies whether the service is managed by the System-V init scripts ('1') or not
#
{% set elk_services = [ ['elasticsearch', 1], ['kibana', 1], ['logstash', 0], ['filebeat', 1], ['metricbeat', 1] ] %}
{% set ip_address = salt['grains.get']('ip4_interfaces:eth0')[0] %}

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

kibana_listen_on_ethernet_iface:
  file.replace:
    - name: "/etc/kibana/kibana.yml"
    - pattern: "^\\s*#\\s*server\\.host:\\s*.*"
    - repl: 'server.host: "{{ ip_address }}"'

kibana_set_elasticsearch_url:
  file.replace:
    - name: "/etc/kibana/kibana.yml"
    - pattern: "^\\s*#\\s*elasticsearch\\.url:\\s*.*"
    - repl: 'elasticsearch.url: "http://{{ ip_address }}:9200"'

# Once we move to Ubuntu 16.04, this might need to change (systemd will be used instead of System V)
#
# TODO: Move this command to options
{% for service in elk_services %}
  {% if service[1] == 1 %}

run_{{ service[0] }}_on_startup:
  cmd.run:
    - name: 'update-rc.d {{ service[0] }} defaults 95 10'

  {% endif %}

{% endfor %}