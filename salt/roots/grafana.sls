{% import 'options.sls' as opts %}

grafana_apt_public_key:
  cmd.run:
    - name: 'curl https://packagecloud.io/gpg.key | sudo apt-key add -'

grafana_apt_repository:
  file.append:
    - name: '/etc/apt/sources.list'
    - text: 'deb https://packagecloud.io/grafana/stable/debian/ jessie main'

grafana_apt_update:
  cmd.run:
    - name: 'apt-get update'

grafana:
  pkg.installed: []

run_grafana_server_on_startup:
  cmd.run:
    - name: 'update-rc.d grafana-server defaults'

grafana-server:
  service.running: []
