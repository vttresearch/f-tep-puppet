# Configure the gateway to the F-TEP services, reverse-proxying to nodes implementing the other classes
class ftep::proxy (
  $vhost_name                      = 'ftep-proxy',
  $vhost_aliases                   = {},
  $default_vhost_dest              = 'http://ftep-drupal',

  $enable_ssl                      = false,
  $enable_sso                      = false,

  $context_path_geoserver          = undef,
  $context_path_resto              = undef,
  $context_path_webapp             = undef,
  $context_path_wps                = undef,
  $context_path_api_v2             = undef,
  $context_path_monitor            = undef,
  $context_path_logs               = undef,
  $context_path_eureka             = undef,
  $context_path_broker             = undef,
  $context_path_gui                = undef,

  $preserve_gui_context_path       = false,
  $graylog_server_url_includes_api = false,

  $tls_cert_path                   = '/etc/pki/tls/certs/ftep_portal.crt',
  $tls_chain_path                  = '/etc/pki/tls/certs/ftep_portal.chain.crt',
  $tls_key_path                    = '/etc/pki/tls/private/ftep_portal.key',
  $tls_cert                        = undef,
  $tls_chain                       = undef,
  $tls_key                         = undef,
) {

  require ::ftep::globals

  contain ::ftep::common::apache

  ensure_packages(['apr-util-pgsql'])
  include ::apache::mod::headers
  include ::apache::mod::proxy
  include ::apache::mod::proxy_wstunnel
  include ::apache::mod::rewrite

  $real_context_path_geoserver = pick($context_path_geoserver, $ftep::globals::context_path_geoserver)
  $real_context_path_resto = pick($context_path_resto, $ftep::globals::context_path_resto)
  $real_context_path_webapp = pick($context_path_webapp, $ftep::globals::context_path_webapp)
  $real_context_path_wps = pick($context_path_wps, $ftep::globals::context_path_wps)
  $real_context_path_api_v2 = pick($context_path_api_v2, $ftep::globals::context_path_api_v2)
  $real_context_path_monitor = pick($context_path_monitor, $ftep::globals::context_path_monitor)
  $real_context_path_logs = pick($context_path_logs, $ftep::globals::context_path_logs)
  $real_context_path_eureka = pick($context_path_eureka, $ftep::globals::context_path_eureka)
  $real_context_path_broker = pick($context_path_broker, $ftep::globals::context_path_broker)
  $real_context_path_gui = pick($context_path_gui, $ftep::globals::context_path_gui)

  $real_dbd_query = pick($ftep::globals::proxy_dbd_query, join([
    "select api_key from ${ftep::globals::proxy_dbd_keys_table}",
    "inner join ${ftep::globals::proxy_dbd_users_table}",
    "on ${ftep::globals::proxy_dbd_keys_table}.owner=ftep_users.uid",
    "where ${ftep::globals::proxy_dbd_users_table}.name=%s;"
  ], ' '))

  $gui_match_path = "^${real_context_path_gui}/(.*)"
  if $preserve_gui_context_path {
    $gui_backend_prefix = "${ftep::globals::default_gui_hostname}${real_context_path_gui}/\$1"
  } else {
    $gui_backend_prefix = "${ftep::globals::default_gui_hostname}\$1"
  }

  if $graylog_server_url_includes_api {
    $graylog_server_url = "${ftep::globals::base_url}${ftep::globals::graylog_api_path}"
  } else {
    $graylog_server_url = "${ftep::globals::base_url}${ftep::globals::graylog_context_path}"
  }

  $default_proxy_config = {
    docroot    => '/var/www/html',
    vhost_name => '_default_', # The default landing site should always be Drupal
    proxy_dest => $default_vhost_dest,
    rewrites   => [
      {
        rewrite_rule => ['^/app$ /app/ [R]']
      },
      {
        rewrite_cond => ['%{HTTP:UPGRADE} ^WebSocket$ [NC]', '%{HTTP:CONNECTION} ^Upgrade$ [NC]'],
        rewrite_rule => ["${gui_match_path}  ws://${gui_backend_prefix} [P]"]
      },
    ]
  }

  # Directory/Location directives - cannot be an empty array...
  $default_directories = [
    {
      'provider'        => 'location',
      'path'            => $real_context_path_logs,
      'custom_fragment' =>
      "RequestHeader set X-Graylog-Server-URL \"${graylog_server_url}\""
    }
  ]

  # Reverse proxied paths
  $default_proxy_pass = [
    {
      'path'   => $real_context_path_geoserver,
      'url'    =>
      "http://${ftep::globals::geoserver_hostname}:${ftep::globals::geoserver_port}${real_context_path_geoserver}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_resto,
      'url'    => "http://${ftep::globals::resto_hostname}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_webapp,
      'url'    => "http://${ftep::globals::webapp_hostname}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_wps,
      'url'    => "http://${ftep::globals::wps_hostname}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_api_v2,
      'url'    =>
      "http://${ftep::globals::server_hostname}:${ftep::globals::server_application_port}${real_context_path_api_v2}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_monitor,
      'url'    => "http://${ftep::globals::monitor_hostname}:${ftep::globals::grafana_port}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_logs,
      'url'    =>
      "http://${ftep::globals::monitor_hostname}:${ftep::globals::graylog_port}${ftep::globals::graylog_context_path}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_eureka,
      'url'    => "http://${ftep::globals::server_hostname}:${ftep::globals::serviceregistry_application_port}/eureka",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_broker,
      'url'    => "http://${ftep::globals::broker_hostname}",
      'params' => { 'retry' => '0' }
    }
  ]

  $default_proxy_pass_match = [
    {
      'path'   => "${gui_match_path}/websockify$",
      'url'    => "ws://${gui_backend_prefix}/websockify",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => "${gui_match_path}",
      'url'    => "http://${gui_backend_prefix}",
      'params' => { 'retry' => '0' }
    }
  ]

  if $enable_sso {
    unless ($tls_cert and $tls_key) {
      fail("ftep::proxy requres \$tls_cert and \$tls_key to be set if \$enable_sso is true")
    }
    contain ::ftep::proxy::shibboleth

    # Add the /Shibboleth.sso SP callback location, enable the minimal support for the root, and add secured paths
    $directories = concat([
      {
        'provider'   => 'location',
        'path'       => '/Shibboleth.sso',
        'sethandler' => 'shib'
      },
      {
        'provider'              => 'location',
        'path'                  => '/',
        'auth_type'             => 'shibboleth',
        'shib_use_headers'      => 'On',
        'shib_request_settings' => { 'requireSession' => '0' },
        'auth_require'          => 'shibboleth',
      },
      {
        'provider'              => 'location',
        'path'                  => $real_context_path_webapp,
        'auth_type'             => 'shibboleth',
        'shib_use_headers'      => 'On',
        'shib_request_settings' => { 'requireSession' => '1' },
        'auth_require'          => 'valid-user',
      },
      {
        'provider'        => 'location',
        'path'            => '/secure',
        'custom_fragment' =>
        "<If \"-n req('Authorization')\">
    AuthType Basic
    AuthName 'F-TEP API access'
    AuthBasicProvider dbd
    AuthDBDUserPWQuery \"${$real_dbd_query}\"
    Require valid-user
    RewriteEngine On
    RewriteCond %{REMOTE_USER} ^(.*)$
    RewriteRule ^(.*)$ - [E=R_U:%1]
    RequestHeader set ${ftep::globals::username_request_header} %{R_U}e
</If>
<Else>
    Require valid-user
    AuthType shibboleth
    ShibRequestSetting requireSession 1
    ShibUseHeaders On
</Else>
"
      }
    ], $default_directories)

    # Insert the callback location at the start of the reverse proxy list
    $proxy_pass = concat([{
      'path'         => '/Shibboleth.sso',
      'url'          => '!',
      'reverse_urls' => [],
      'params'       => { 'retry' => '0' }
    }], $default_proxy_pass)
    $proxy_pass_match = $default_proxy_pass_match
  } else {
    $directories = concat([
      {
        'provider'        => 'location',
        'path'            => '/secure',
        'custom_fragment' =>
        "<If \"-n req('Authorization')\">
    AuthType Basic
    AuthName 'F-TEP API access'
    AuthBasicProvider dbd
    AuthDBDUserPWQuery \"${real_dbd_query}\"
    Require valid-user
    RewriteEngine On
    RewriteCond %{REMOTE_USER} ^(.*)$
    RewriteRule ^(.*)$ - [E=R_U:%1]
    RequestHeader set ${ftep::globals::username_request_header} %{R_U}e
</If>
"
      }], $default_directories)
    $proxy_pass = $default_proxy_pass
    $proxy_pass_match = $default_proxy_pass_match
  }

  $vhost_aliases.each | String $alias, Hash $tls_vars | {
    apache::vhost { "redirect ${alias} non-ssl":
      servername      => $alias,
      port            => '80',
      docroot         => '/var/www/redirect',
      redirect_status => 'permanent',
      redirect_dest   => "http://${vhost_name}/"
    }
  }

  if $enable_ssl {
    unless ($tls_cert and $tls_key) {
      fail("ftep::proxy requres \$tls_cert and \$tls_key to be set if \$enable_ssl is true")
    }

    file { $tls_cert_path:
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => $tls_cert,
    }

    if $tls_chain {
      file { $tls_chain_path:
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => $tls_chain,
      }
      $real_tls_chain_path = $tls_chain_path
    } else {
      $real_tls_chain_path = undef
    }

    file { $tls_key_path:
      ensure  => present,
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      content => $tls_key,
    }

    $vhost_aliases.each | String $alias, Hash $tls_vars | {
      apache::vhost { "redirect ${alias} ssl":
        servername      => $alias,
        port            => '443',
        docroot         => '/var/www/redirect',
        redirect_status => 'permanent',
        redirect_dest   => "https://${vhost_name}/",
        ssl             => true,
        ssl_cert        => pick($tls_vars["tls_cert_path"], $tls_cert_path),
        ssl_chain       => pick($tls_vars["tls_cert_chain_path"], $real_tls_chain_path),
        ssl_key         => pick($tls_vars["tls_key_path"], $tls_key_path),
      }
    }
    apache::vhost { "redirect ${vhost_name} non-ssl":
      servername      => $vhost_name,
      port            => '80',
      docroot         => '/var/www/redirect',
      redirect_status => 'permanent',
      redirect_dest   => "https://${vhost_name}/"
    }
    apache::vhost { $vhost_name:
      servername       => $vhost_name,
      port             => '443',
      ssl              => true,
      ssl_cert         => $tls_cert_path,
      ssl_chain        => $real_tls_chain_path,
      ssl_key          => $tls_key_path,
      default_vhost    => true,
      request_headers  => [
        'set X-Forwarded-Proto "https"'
      ],
      directories      => $directories,
      proxy_pass       => $proxy_pass,
      proxy_pass_match => $proxy_pass_match,
      *                => $default_proxy_config,
    }
  } else {
    apache::vhost { $vhost_name:
      servername       => $vhost_name,
      port             => '80',
      default_vhost    => true,
      directories      => $directories,
      proxy_pass       => $proxy_pass,
      proxy_pass_match => $proxy_pass_match,
      *                => $default_proxy_config
    }
  }

  if $facts['selinux'] {
    ensure_resource('selinux::boolean', 'httpd_can_network_connect_db', { ensure => true })
    ensure_resource('selinux::boolean', 'httpd_can_network_connect', { ensure => true })
  }

  class { 'apache::mod::authn_dbd':
    authn_dbd_params   => join([
      "host=${ftep::globals::proxy_dbd_host}",
      "port=${ftep::globals::proxy_dbd_port}",
      "user=${ftep::globals::proxy_dbd_username}",
      "password=${ftep::globals::proxy_dbd_password}",
      "dbname=${ftep::globals::ftep_db_v2_name}"
    ], ' '),
    authn_dbd_dbdriver => "${ftep::globals::proxy_dbd_dbdriver}",
    authn_dbd_min      => 1,
    authn_dbd_max      => 8,
    authn_dbd_keep     => 4,
    authn_dbd_exptime  => 30,
  }

}
