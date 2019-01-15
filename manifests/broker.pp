class ftep::broker (
  $activemq_version = '5.14.5',
  $service_ensure   = true,
  $service_enable   = true,
  $service_name     = 'f-tep-broker',
) {

  require ::ftep::globals
  require ::ftep::common::java
  require ::epel

  $activemq_prereq = [ 'wget', 'unzip' ]
  package { $activemq_prereq: ensure => 'installed' } ->

  class { 'activemq':
    install              => 'source',
    version              => "${activemq_version}",
    install_dependencies => false,
    install_destination  => '/opt', # Default value
    create_user          => true, # Default value
    process_user         => 'activemq', # Default value
    disable              => true,
    disableboot          => true,
    service_autorestart  => false,
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
    require => Puppi::Netinstall['netinstall_activemq'],
  }

  service { $service_name:
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [File["/usr/lib/systemd/system/${service_name}.service"]],
  }

}

