class ftep::monitor::graylog_server (
  $db_secret                  = undef,
  $db_sha256                  = undef,
  $db_bind_ip                 = '127.0.0.1',

  $listen_host                = '0.0.0.0',
  $listen_port                = undef,
  $context_path               = undef,

  $mongodb_version            = '4.4.6',

  $elasticsearch_repo_version = '6.x',
  $elasticsearch_version      = '6.8.16',

  # If <3.0, set ftep::proxy::graylog_server_url_includes_api to true
  $graylog_repo_version       = '4.0',
  $graylog_version            = '4.0.8',
) {

  require ::epel

  contain ::ftep::common::java

  $real_db_secret = pick($db_secret, $ftep::globals::graylog_secret)
  $real_db_sha256 = pick($db_sha256, $ftep::globals::graylog_sha256)
  $real_listen_port = pick($listen_port, $ftep::globals::graylog_port)
  $real_context_path = pick($context_path, $ftep::globals::graylog_context_path)

  class { ::mongodb::globals:
    manage_package_repo => true,
    version             => $mongodb_version
  } ->
  class { ::mongodb::server:
    bind_ip => [$db_bind_ip],
  }

  $es_module_version = ftep::module_version('elasticsearch')

  if versioncmp($es_module_version, '6.3') < 0 {
    class { ::elasticsearch:
      repo_version => $elasticsearch_repo_version,
      version      => $elasticsearch_version,
      manage_repo  => true,
    }
    ->
    ::elasticsearch::instance { 'graylog':
      config => {
        'cluster.name' => 'graylog',
        'network.host' => $db_bind_ip,
      }
    }

    # Fix the symlinked scripts folder which breaks on ES > 6.x
    exec { 'fix_es_scripts_link':
      command =>
        'rm /etc/elasticsearch/graylog/scripts && mkdir /etc/elasticsearch/graylog/scripts && chown elasticsearch:elasticsearch /etc/elasticsearch/graylog/scripts'
      ,
      path    => ['/bin', '/usr/bin'],
      onlyif  => 'test -L /etc/elasticsearch/graylog/scripts',
      require => [File['/etc/elasticsearch/graylog/scripts']],
      before  => [Service['elasticsearch-instance-graylog']],
    }

  } elsif versioncmp($es_module_version, '7.0') < 0 {

    warning("This module is not tested with elastic-elasticsearch >= 6.1.0")

    class { 'elastic_stack::repo':
      oss     => true,
      version => $elasticsearch_repo_version,
    }

    class { ::elasticsearch:
      oss     => true,
      version => $elasticsearch_version,
    } ->
    ::elasticsearch::instance { 'graylog':
      config => {
        'cluster.name' => 'graylog',
        'network.host' => $db_bind_ip,
      }
    }
  } else { # elastic-elasticsearch >= 7.0.0

    warning("This module is not tested with elastic-elasticsearch >= 6.1.0")

    class { 'elastic_stack::repo':
      oss     => true,
      version => $elasticsearch_repo_version,
    }

    class { ::elasticsearch:
      oss     => true,
      version => $elasticsearch_version,
      config  => {
        'cluster' => {
          'name' => 'graylog',
        },
        'network' => {
          'host' => $db_bind_ip,
        }
      }
    }
  }

  if versioncmp($graylog_repo_version, '3.0') < 0 {
    $graylog_server_config = {
      password_secret          => $real_db_secret, # Fill in your password secret
      root_password_sha2       => $real_db_sha256, # Fill in your root password hash
      web_listen_uri           => "http://${listen_host}:${real_listen_port}${real_context_path}/",
      rest_listen_uri          => "http://${listen_host}:${real_listen_port}${real_context_path}/api/",
      usage_statistics_enabled => false,
    }
  } else {
    $graylog_server_config = {
      password_secret          => $real_db_secret, # Fill in your password secret
      root_password_sha2       => $real_db_sha256, # Fill in your root password hash
      http_bind_address        => "${listen_host}:${real_listen_port}",
      http_publish_uri         => "http://${listen_host}:${real_listen_port}${real_context_path}/",
      usage_statistics_enabled => false,
    }
  }

  class { ::graylog::repository:
    version => $graylog_repo_version
  } ->
  class { ::graylog::server:
    package_version => $graylog_version,
    config          => $graylog_server_config,
    require         => [Yumrepo['graylog'], Service['elasticsearch-instance-graylog']],
  }

}
