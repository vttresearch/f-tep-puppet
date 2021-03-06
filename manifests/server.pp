class ftep::server (
  $component_name                     = 'f-tep-server',

  $install_path                       = '/var/f-tep/server',
  $config_file                        = '/var/f-tep/server/f-tep-server.conf',
  $logging_config_file                = '/var/f-tep/server/log4j2.xml',
  $properties_file                    = '/var/f-tep/server/application.properties',

  $service_enable                     = true,
  $service_ensure                     = 'running',

  $telegraf_enable                    = true,

  $java_opts                          = '',

  # f-tep-server.properties config
  $application_port                   = undef,
  $grpc_port                          = undef,

  $management_port                    = undef,
  $management_address                 = '127.0.0.1',
  $management_context_path            = '/manage',

  $serviceregistry_user               = undef,
  $serviceregistry_pass               = undef,
  $serviceregistry_host               = undef,
  $serviceregistry_port               = undef,
  $serviceregistry_url                = undef,

  $jdbc_url                           = undef,
  $jdbc_driver                        = 'org.postgresql.Driver',
  $jdbc_user                          = undef,
  $jdbc_password                      = undef,
  $jdbc_datasource_class_name         = 'org.postgresql.ds.PGSimpleDataSource',

  $api_base_path                      = '/secure/api/v2.0',
  $api_username_request_header        = undef,
  $api_email_request_header           = undef,
  $api_security_mode                  = 'NONE',

  $zoomanager_hostname                = undef,
  $zoomanager_grpc_port               = undef,

  $local_worker_hostname              = 'ftep-worker',
  $local_worker_grpc_port             = undef,

  # Pattern for building GUI URLs, may include the subsituted variables '__PORT__', '__JOB_UUID__'
  # For simple ftep::proxy proxying (default if this is undef): http://example.com/gui/:__PORT__/
  # For Traefik proxying: http://example.com/gui/__JOB_UUID__/
  $gui_mode                           = 'SIMPLE',
  $gui_url_pattern                    = undef,
  $traefik_api_url                    = undef,
  $traefik_admin_user                 = undef,
  $traefik_admin_password             = undef,
  $traefik_enable_sso_headers         = true,

  $graylog_api_url                    = undef,
  $graylog_api_username               = undef,
  $graylog_api_password               = undef,

  $output_products_dir                = 'outputProducts',
  $refdata_dir                        = 'refData',

  $geoserver_enabled                  = true,
  $geoserver_url                      = undef,
  $geoserver_external_url             = undef,
  $geoserver_username                 = undef,
  $geoserver_password                 = undef,

  $resto_enabled                      = true,
  $resto_url                          = undef,
  $resto_external_products_collection = 'ftepInputs',
  $resto_external_products_model      = 'RestoModel_Ftep_Input',
  $resto_refdata_collection           = 'ftepRefData',
  $resto_refdata_model                = 'RestoModel_Ftep_Reference',
  $resto_output_products_collection   = 'ftepOutputs',
  $resto_output_products_model        = 'RestoModel_Ftep_Output',
  $resto_username                     = undef,
  $resto_password                     = undef,

  $broker_url                         = undef,
  $broker_username                    = undef,
  $broker_password                    = undef,

  $custom_config_properties           = {},
) {

  require ::ftep::globals

  contain ::ftep::common::datadir
  contain ::ftep::common::java
  # User and group are set up by the RPM if not included here
  contain ::ftep::common::user

  # This could potentially be on its own node, but it's easer to encapsulate it here
  contain ::ftep::serviceregistry

  $real_application_port = pick($application_port, $ftep::globals::server_application_port)
  $real_grpc_port = pick($grpc_port, $ftep::globals::server_grpc_port)
  $real_management_port = pick($management_port, $ftep::globals::server_management_port)

  $real_serviceregistry_user = pick($serviceregistry_user, $ftep::globals::serviceregistry_user)
  $real_serviceregistry_pass = pick($serviceregistry_pass, $ftep::globals::serviceregistry_pass)
  $real_serviceregistry_host = pick($serviceregistry_host, $ftep::globals::server_hostname)
  $real_serviceregistry_port = pick($serviceregistry_port, $ftep::globals::serviceregistry_application_port)
  $serviceregistry_creds = "${real_serviceregistry_user}:${real_serviceregistry_pass}"
  $serviceregistry_server = "${real_serviceregistry_host}:${real_serviceregistry_port}"
  $real_serviceregistry_url = pick($serviceregistry_url,
    "http://${serviceregistry_creds}@${serviceregistry_server}/eureka/")

  $default_jdbc_url =
    "jdbc:postgresql://${::ftep::globals::db_hostname}/${::ftep::globals::ftep_db_v2_name}?stringtype=unspecified"
  $real_db_url = pick($jdbc_url, $default_jdbc_url)
  $real_db_user = pick($jdbc_user, $::ftep::globals::ftep_db_username)
  $real_db_pass = pick($jdbc_password, $::ftep::globals::ftep_db_password)

  $real_api_username_request_header = pick($api_username_request_header, $ftep::globals::username_request_header)
  $real_api_email_request_header = pick($api_email_request_header, $ftep::globals::email_request_header)

  $real_geoserver_url = pick($geoserver_url, "${ftep::globals::base_url}${ftep::globals::context_path_geoserver}/")
  $real_geoserver_external_url = pick($geoserver_external_url,
    "${ftep::globals::base_url}${ftep::globals::context_path_geoserver}/")
  $real_geoserver_username = pick($geoserver_username, $ftep::globals::geoserver_ftep_username)
  $real_geoserver_password = pick($geoserver_username, $ftep::globals::geoserver_ftep_password)

  $real_resto_url = pick($resto_url, "${ftep::globals::base_url}${ftep::globals::context_path_resto}/")
  $real_resto_username = pick($resto_username, $ftep::globals::resto_ftep_username)
  $real_resto_password = pick($resto_username, $ftep::globals::resto_ftep_password)

  $real_broker_url= pick($broker_url, "${ftep::globals::base_url}${ftep::globals::context_path_broker}/")
  $real_broker_username = pick($broker_username, $ftep::globals::broker_ftep_username)
  $real_broker_password = pick($broker_password, $ftep::globals::broker_ftep_password)

  $real_graylog_api_url = pick($graylog_api_url, "${ftep::globals::base_url}${ftep::globals::graylog_api_path}")
  $real_graylog_api_username = pick($graylog_api_username, $ftep::globals::graylog_api_ftep_username)
  $real_graylog_api_password = pick($graylog_api_password, $ftep::globals::graylog_api_ftep_password)

  $real_gui_url_pattern = pick($gui_url_pattern, "${ftep::globals::base_url}/gui/:__PORT__/")
  $real_traefik_api_url = pick($traefik_api_url, "http://${ftep::globals::default_gui_hostname}:${ftep::globals::traefik_service_port}/api/providers/rest")
  $real_traefik_admin_user = pick($traefik_admin_user, $ftep::globals::traefik_user)
  $real_traefik_admin_password = pick($traefik_admin_password, $ftep::globals::traefik_password)

  ensure_packages(['f-tep-server'], {
    ensure  => 'latest',
    name    => 'f-tep-server',
    tag     => 'ftep',
    require => Yumrepo['ftep'],
    notify  => Service['f-tep-server'],
  })

  file { ["${ftep::common::datadir::data_basedir}/${output_products_dir}", "${ftep::common::datadir::data_basedir}/${
    refdata_dir}"]:
    ensure  => directory,
    owner   => $ftep::globals::user,
    group   => $ftep::globals::group,
    mode    => '755',
    recurse => false,
    require => File[$ftep::common::datadir::data_basedir],
  }

  file { $config_file:
    ensure  => 'present',
    owner   => $ftep::globals::user,
    group   => $ftep::globals::group,
    content =>
      "JAVA_OPTS=\"-DLog4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager ${java_opts}\""
    ,
    require => Package['f-tep-server'],
    notify  => Service['f-tep-server'],
  }

  ::ftep::logging::log4j2 { $logging_config_file:
    ftep_component        => $component_name,
    require               => Package['f-tep-server'],
    notify                => Service['f-tep-server'],
  }

  file { $properties_file:
    ensure  => 'present',
    owner   => $ftep::globals::user,
    group   => $ftep::globals::group,
    content => epp('ftep/server/application.properties.epp', {
      'logging_config_file'                => $logging_config_file,
      'server_port'                        => $real_application_port,
      'grpc_port'                          => $real_grpc_port,
      'management_port'                    => $real_management_port,
      'management_address'                 => $management_address,
      'management_context_path'            => $management_context_path,
      'serviceregistry_url'                => $real_serviceregistry_url,
      'jdbc_driver'                        => $jdbc_driver,
      'jdbc_url'                           => $real_db_url,
      'jdbc_user'                          => $real_db_user,
      'jdbc_password'                      => $real_db_pass,
      'jdbc_data_source_class_name'        => $jdbc_datasource_class_name,
      'api_base_path'                      => $api_base_path,
      'api_username_request_header'        => $real_api_username_request_header,
      'api_email_request_header'           => $real_api_email_request_header,
      'api_security_mode'                  => $api_security_mode,
      'graylog_api_url'                    => $real_graylog_api_url,
      'graylog_api_username'               => $real_graylog_api_username,
      'graylog_api_password'               => $real_graylog_api_password,
      'gui_mode'                           => $gui_mode,
      'gui_url_pattern'                    => $real_gui_url_pattern,
      'traefik_api_url'                    => $real_traefik_api_url,
      'traefik_admin_user'                 => $real_traefik_admin_user,
      'traefik_admin_password'             => $real_traefik_admin_password,
      'traefik_enable_sso_headers'         => $traefik_enable_sso_headers,
      'output_products_dir'                => "${ftep::common::datadir::data_basedir}/${output_products_dir}",
      'refdata_dir'                        => "${ftep::common::datadir::data_basedir}/${refdata_dir}",
      'geoserver_enabled'                  => $geoserver_enabled,
      'geoserver_url'                      => $real_geoserver_url,
      'geoserver_external_url'             => $real_geoserver_external_url,
      'geoserver_username'                 => $real_geoserver_username,
      'geoserver_password'                 => $real_geoserver_password,
      'resto_enabled'                      => $resto_enabled,
      'resto_url'                          => $real_resto_url,
      'resto_external_products_collection' => $resto_external_products_collection,
      'resto_external_products_model'      => $resto_external_products_model,
      'resto_refdata_collection'           => $resto_refdata_collection,
      'resto_refdata_model'                => $resto_refdata_model,
      'resto_output_products_collection'   => $resto_output_products_collection,
      'resto_output_products_model'        => $resto_output_products_model,
      'resto_username'                     => $real_resto_username,
      'resto_password'                     => $real_resto_password,
      'broker_url'                         => $real_broker_url,
      'broker_username'                    => $real_broker_username,
      'broker_password'                    => $real_broker_password,
      'custom_properties'                  => $custom_config_properties,
    }),
    require => Package['f-tep-server'],
    notify  => Service['f-tep-server'],
  }

  $default_service_requires = [Package['f-tep-server'], File[$properties_file]]
  $service_requires = defined(Class["::ftep::db"]) ? {
    true    => concat($default_service_requires, Class['::ftep::db']),
    default => $default_service_requires
  }

  service { 'f-tep-server':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => $service_requires,
  }

  if $telegraf_enable {
    ftep::monitor::telegraf_jolokia_input { $component_name:
      management_context_path => $management_context_path,
      management_port         => $real_management_port,
    }
  }

}
