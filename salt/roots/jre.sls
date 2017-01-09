purge_open_jdk:
  cmd.run:
    - name: 'apt-get purge openjdk-\*'

create_java_dir:
  cmd.run:
    - name: 'mkdir -p /usr/local/java'

download_jre_package:
  cmd.run:
    - name: 'curl -L -O http://ie.archive.ubuntu.com/funtoo/distfiles/oracle-java/jre-8u112-linux-x64.tar.gz'
    # - name: 'curl -L -O http://ftp.osuosl.org/pub/funtoo/distfiles/oracle-java/jre-8u112-linux-x64.tar.gz'
    - cwd: '/root'

copy_package_to_java_dir:
  cmd.run:
    - name: 'cp -r jre-8u112-linux-x64.tar.gz /usr/local/java'
    - cwd: '/root'

# TODO: Move the JRE version and the package URL to options

make_jre_package_executable:
  cmd.run:
    - name: 'chmod a+x jre-8u112-linux-x64.tar.gz'
    - cwd: '/usr/local/java'

unpack_jre_package:
  cmd.run:
    - name: 'tar xvzf jre-8u112-linux-x64.tar.gz'
    - cwd: '/usr/local/java'

export_java_paths_in_profile:
  file.append:
    - name: '/etc/profile'
    - source: '/srv/salt/files/profile_modification.rc'    

inform_system_about_jre_location:
  cmd.run:
    - name: 'update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/jre1.8.0_112/bin/java" 1'

inform_system_about_jws_location:
  cmd.run:
    - name: 'update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/local/java/jre1.8.0_112/bin/javaws" 1'

set_default_java:
  cmd.run:
    - name: 'update-alternatives --set java /usr/local/java/jre1.8.0_112/bin/java'

set_default_jws:
  cmd.run:
    - name: 'update-alternatives --set javaws /usr/local/java/jre1.8.0_112/bin/javaws'

# This does not seem to work (though it works when executed manually)
#
reload_system_wide_profile:
  cmd.run:
    - name: '. /etc/profile'

# This only works in Ubuntu 16.04 (hopefully)
#
# jre:
#   pkg.installed: 
#     - pkgs:
#       - openjdk-8-jre