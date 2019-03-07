class ftep::serviceregistry (
  $component_name              = 'f-tep-serviceregistry',

  $install_path                = '/var/f-tep/serviceregistry',
  $config_file                 = '/var/f-tep/serviceregistry/f-tep-serviceregistry.conf',
  $logging_config_file         = '/var/f-tep/serviceregistry/log4j2.xml',
  $properties_file             = '/var/f-tep/serviceregistry/application.properties',

  $service_enable              = true,
  $service_ensure              = 'running',

  $telegraf_enable             = true,

  $java_opts                          = '',

  # f-tep-serviceregistry application.properties config
  $application_port            = undef,

  $management_port             = undef,
  $management_address          = '127.0.0.1',
  $management_context_path     = '/manage',

  $serviceregistry_user        = undef,
  $serviceregistry_pass        = undef,

  $custom_config_properties    = {},
) {

  require ::ftep::globals

  contain ::ftep::common::java
  # User and group are set up by the RPM if not included here
  contain ::ftep::common::user

  $real_application_port = pick($application_port, $ftep::globals::serviceregistry_application_port)
  $real_management_port = pick($management_port, $ftep::globals::serviceregistry_management_port)

  $real_serviceregistry_user = pick($serviceregistry_user, $ftep::globals::serviceregistry_user)
  $real_serviceregistry_pass = pick($serviceregistry_pass, $ftep::globals::serviceregistry_pass)

  # JDK is necessary to compile service stubs
  ensure_packages(['java-1.8.0-openjdk-devel'])

  ensure_packages(['f-tep-serviceregistry'], {
    ensure  => 'latest',
    name    => 'f-tep-serviceregistry',
    tag     => 'ftep',
    notify  => Service['f-tep-serviceregistry'],
    require => Yumrepo['ftep'],
  })

  file { $config_file:
    ensure  => 'present',
    owner   => $ftep::globals::user,
    group   => $ftep::globals::group,
    content =>
      "JAVA_OPTS=\"-DLog4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager ${java_opts}\""
    ,
    require => Package['f-tep-serviceregistry'],
    notify  => Service['f-tep-serviceregistry'],
  }

  ::ftep::logging::log4j2 { $logging_config_file:
    ftep_component        => $component_name,
    require               => Package['f-tep-serviceregistry'],
    notify                => Service['f-tep-serviceregistry'],
  }

  file { $properties_file:
    ensure  => 'present',
    owner   => $ftep::globals::user,
    group   => $ftep::globals::group,
    content => epp('ftep/serviceregistry/application.properties.epp', {
      'logging_config_file'         => $logging_config_file,
      'server_port'                 => $real_application_port,
      'management_port'             => $real_management_port,
      'management_address'          => $management_address,
      'management_context_path'     => $management_context_path,
      'serviceregistry_user'        => $real_serviceregistry_user,
      'serviceregistry_pass'        => $real_serviceregistry_pass,
      'custom_properties'           => $custom_config_properties,
    }),
    require => Package['f-tep-serviceregistry'],
    notify  => Service['f-tep-serviceregistry'],
  }

  service { 'f-tep-serviceregistry':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [Package['f-tep-serviceregistry'], File[$properties_file]],
  }

  if $telegraf_enable {
    ftep::monitor::telegraf_jolokia_input { $component_name:
      management_context_path => $management_context_path,
      management_port         => $real_management_port,
    }
  }

}
