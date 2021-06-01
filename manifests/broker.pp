class ftep::broker (
  $activemq_version = '5.14.5',
  $service_ensure   = true,
  $service_enable   = true,
  $service_name     = 'f-tep-broker',
  $source_url       = 'http://archive.apache.org/dist/activemq/5.14.5/apache-activemq-5.14.5-bin.zip',
) {

  require ::ftep::globals
  require ::ftep::common::java
  require ::epel

  ensure_packages(['wget', 'unzip'])

  class { 'activemq':
    install              => 'source',
    install_source       => $source_url,
    version              => $activemq_version,
    install_dependencies => false,
    install_destination  => '/opt', # Default value
    create_user          => true, # Default value
    process_user         => 'activemq', # Default value
    disable              => true,
    disableboot          => true,
    service_autorestart  => false,
  }

  # Make sure the activemq binary is executable
  file { "/opt/apache-activemq-${activemq_version}/bin/activemq":
    mode    => '0755',
    require => [Puppi::Netinstall['netinstall_activemq']],
  }

  $service_unit_content = "[Unit]
Description=Apache ActiveMQ
After=network-online.target

[Service]
Type=forking
WorkingDirectory=/opt/activemq
ExecStart=/opt/activemq/bin/activemq start
ExecStop=/opt/activemq/bin/activemq stop
Restart=on-abort
User=activemq
Group=activemq

[Install]
WantedBy=multi-user.target
"

  file { "/usr/lib/systemd/system/${service_name}.service":
    content => $service_unit_content,
    ensure  => present,
  }

  service { $service_name:
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      File["/opt/apache-activemq-${activemq_version}/bin/activemq"],
      File["/usr/lib/systemd/system/${service_name}.service"]
    ],
  }

}

