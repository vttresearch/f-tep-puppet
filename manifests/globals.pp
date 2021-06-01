# Class for setting cross-class global overrides.
class ftep::globals (
  $manage_package_repo              = true,

  # Base URL for ftep::proxy
  $base_url                         = "http://${facts['fqdn']}",

  # Context paths for reverse proxy
  $context_path_geoserver           = '/geoserver',
  $context_path_resto               = '/resto',
  $context_path_webapp              = '/app',
  $context_path_wps                 = '/secure/wps',
  $context_path_api_v2              = '/secure/api/v2.0',
  $context_path_monitor             = '/monitor',
  $context_path_logs                = '/logs',
  $context_path_eureka              = '/eureka',
  $context_path_broker              = '/broker',
  $context_path_gui                 = '/gui',

  # System user
  $user                             = 'ftep',
  $group                            = 'ftep',

  # Hostnames and IPs for components
  $db_hostname                      = 'ftep-db',
  $drupal_hostname                  = 'ftep-drupal',
  $wordpress_hostname               = 'ftep-wordpress',
  $geoserver_hostname               = 'ftep-geoserver',
  $proxy_hostname                   = 'ftep-proxy',
  $webapp_hostname                  = 'ftep-webapp',
  $wps_hostname                     = 'ftep-wps',
  $server_hostname                  = 'ftep-server',
  $monitor_hostname                 = 'ftep-monitor',
  $resto_hostname                   = 'ftep-resto',
  $broker_hostname                  = 'ftep-broker',
  $default_gui_hostname             = 'ftep-traefik',

  $hosts_override                   = {},

  # SSH authorized_keys contents
  $ssh_authorized_keys              = {},

  # All classes should share this database config, or override it if necessary
  $ftep_db_name                     = 'ftep',
  $ftep_db_v2_name                  = 'ftep_v2',
  $ftep_db_username                 = 'ftepuser',
  $ftep_db_password                 = 'fteppass',
  $ftep_db_resto_name               = 'ftep_resto',
  $ftep_db_resto_username           = 'ftepresto',
  $ftep_db_resto_password           = 'fteprestopass',
  $ftep_db_resto_su_username        = 'fteprestoadmin',
  $ftep_db_resto_su_password        = 'fteprestoadminpass',
  $ftep_db_zoo_name                 = 'ftep_zoo',
  $ftep_db_zoo_username             = 'ftepzoo',
  $ftep_db_zoo_password             = 'ftepzoopass',
  $wordpress_db_name                = 'ftep_wordpress',
  $wordpress_db_username            = 'ftepwordpress',
  $wordpress_db_password            = 'ftepwordpresspass',

  # SSO configuration
  $username_request_header          = 'REMOTE_USER',
  $email_request_header             = 'REMOTE_EMAIL',

  # Eureka config
  $serviceregistry_user             = 'ftepeureka',
  $serviceregistry_pass             = 'ftepeurekapass',

  # Traefik admin user config, generate with htpasswd
  $traefik_user                     = 'fteptraefik',
  $traefik_password                 = 'fteptraefikpass',
  $traefik_admin_port               = 8000,
  $traefik_service_port             = 10000,

  # App server config for HTTP and gRPC
  $serviceregistry_application_port = 8761,
  $serviceregistry_management_port  = 8161,

  $server_application_port          = 8090,
  $server_management_port           = 8190,
  $server_grpc_port                 = 6565,

  $worker_application_port          = 8091,
  $worker_management_port           = 8191,
  $worker_grpc_port                 = 6566,

  $zoomanager_application_port      = 8092,
  $zoomanager_management_port       = 8192,
  $zoomanager_grpc_port             = 6567,

  # Geoserver config
  $geoserver_port                   = 9080,
  $geoserver_stopport               = 9079,
  $geoserver_ftep_username          = 'ftepgeoserver',
  $geoserver_ftep_password          = 'ftepgeoserverpass',

  # Resto config
  $resto_ftep_username              = 'ftepresto',
  $resto_ftep_password              = 'fteprestopass',

  # Broker config
  $broker_ftep_username             = 'ftepbroker',
  $broker_ftep_password             = 'ftepbrokerpass',

  # monitor config
  $grafana_port                     = 8089,
  $monitor_data_port                = 8086,

  # graylog config
  $graylog_secret                   =
  'bQ999ugSIvHXfWQqrwvAomNxaMsErX6I4UWicpS9ZU8EDmuFnhX9AmcoM43s4VGKixd2f6d6cELbRuPWO5uayHnBrBbNWVth',
  # sha256 of graylogpass:
  $graylog_sha256                   = 'a7fdfe53e2a13cb602def10146388c65051c67e60ee55c051668a1c709449111',
  $graylog_port                     = 8087,
  $graylog_context_path             = '/logs',
  $graylog_api_path                 = '/logs/api',
  $graylog_gelf_udp_port            = 12201,
  $graylog_api_ftep_username        = 'ftepgraylog',
  $graylog_api_ftep_password        = 'ftepgraylogpass',

  $enable_log4j2_graylog            = false,

  # API Proxy config
  $proxy_dbd_username               = 'ftepproxyuser',
  $proxy_dbd_password               = 'ftepproxypassword',
  $proxy_dbd_host                   = 'ftep-db',
  $proxy_dbd_port                   = 5432,
  $proxy_dbd_dbdriver               = 'pgsql',
  $proxy_dbd_query                  = undef,
  $proxy_dbd_users_table            = 'ftep_users',
  $proxy_dbd_keys_table             = 'ftep_api_keys',
) {

  # Alias reverse-proxy hosts via hosts file
  ensure_resources(host, $hosts_override)

  # Manage keys globally
  ensure_resources(ssh_authorized_key, $ssh_authorized_keys)

  # Setup of the repo only makes sense globally, so we are doing this here.
  if($manage_package_repo) {
    require ::ftep::repo
  }

  if $facts['os']['family'] == 'Debian' {
    class { '::apt': }
  }
}
