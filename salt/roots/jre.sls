{% import 'options.sls' as opts %}

purge_open_jdk:
  cmd.run:
    - name: 'apt-get purge openjdk-\*'

create_java_dir:
  cmd.run:
    - name: 'mkdir -p /usr/local/java'

download_jre_package:
  cmd.run:
    - name: 'curl -L -O {{ opts.jre_package_url_dir }}/{{ opts.jre_package_url_file }}'    
    - cwd: '/root'

copy_package_to_java_dir:
  cmd.run:
    - name: 'cp -r {{ opts.jre_package_url_file }} /usr/local/java'
    - cwd: '/root'

make_jre_package_executable:
  cmd.run:
    - name: 'chmod a+x {{ opts.jre_package_url_file }}'
    - cwd: '/usr/local/java'

unpack_jre_package:
  cmd.run:
    - name: 'tar xvzf {{ opts.jre_package_url_file }}'
    - cwd: '/usr/local/java'

export_java_paths_in_profile:
  file.append:
    - name: '/etc/profile'
    - source: '/srv/salt/files/profile_modification.rc'    

inform_system_about_jre_location:
  cmd.run:
    - name: 'update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/{{ opts.jre_version }}/bin/java" 1'

inform_system_about_jws_location:
  cmd.run:
    - name: 'update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/local/java/{{ opts.jre_version }}/bin/javaws" 1'

set_default_java:
  cmd.run:
    - name: 'update-alternatives --set java /usr/local/java/{{ opts.jre_version }}/bin/java'

set_default_jws:
  cmd.run:
    - name: 'update-alternatives --set javaws /usr/local/java/{{ opts.jre_version }}/bin/javaws'

# This does not seem to work (though it works when executed manually)
#
reload_system_wide_profile:
  cmd.run:
    - name: '. /etc/profile'

# This works in Ubuntu 16.04 (hopefully)
#
# jre:
#   pkg.installed: 
#     - pkgs:
#       - openjdk-8-jre