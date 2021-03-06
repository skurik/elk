{% set jre_version = 'jre1.8.0_112' %}
{% set jre_package_url_dir = 'http://ie.archive.ubuntu.com/funtoo/distfiles/oracle-java/' %}
{% set jre_package_url_file = 'jre-8u112-linux-x64.tar.gz' %}
{% set iqube_iis_log_dir = '/var/log/iis/iqube/*.log' %}
{% set tc_iis_log_dir = '/var/log/iis/tc/*.log' %}
{% set es_data_dir = '/srv/es' %}

# Where can beats reach logstash
#
{% set logstash_host = 'localhost' %}

{% set ip_address = salt['grains.get']('ipv4')[0] %}