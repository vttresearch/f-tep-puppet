class ftep::monitor::graylog_collector (
  String $config_file                 = '/etc/graylog/collector-sidecar/collector_sidecar.yml',
  Optional[String] $graylog_api_url   = undef,
  Integer $update_interval            = 10,
  String $node_id                     = $::hostname,
  String $collector_id                = 'file:/etc/graylog/collector-sidecar/collector-id',
  String $cache_path                  = '/var/cache/graylog/collector-sidecar',
  String $log_path                    = '/var/log/graylog/collector-sidecar',
  Integer $log_rotation_time          = 86400,
  Integer $log_max_age                = 604800,
  Array $tags                         = ['syslog'],
  String $filebeat_configuration_path = '/etc/graylog/collector-sidecar/generated/filebeat.yml',
) {

  require ::ftep::globals

  $real_graylog_api_url = pick($graylog_api_url, "${ftep::globals::base_url}${ftep::globals::graylog_api_path}")

  package { 'collector-sidecar':
    name    => 'collector-sidecar',
    ensure  => 'present',
    require => Yumrepo['ftep'],
  }

  file { $config_file:
    ensure  => present,
    mode    => '640',
    content => epp('ftep/graylog-collector/collector_sidecar.yml.epp', {
      'graylog_api_url'             => $real_graylog_api_url,
      'update_interval'             => $update_interval,
      'node_id'                     => $node_id,
      'collector_id'                => $collector_id,
      'cache_path'                  => $cache_path,
      'log_path'                    => $log_path,
      'log_rotation_time'           => $log_rotation_time,
      'log_max_age'                 => $log_max_age,
      'tags'                        => $tags,
      'filebeat_configuration_path' => $filebeat_configuration_path,
    }),
    require => Package['collector-sidecar'],
    notify  => Service['collector-sidecar'],
  }

  exec { 'install_sidecar_service':
    creates => '/etc/systemd/system/collector-sidecar.service',
    command => '/usr/bin/graylog-collector-sidecar -service install',
    require => [Package['collector-sidecar'], File[$config_file]],
  }

  service { 'collector-sidecar':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [Package['collector-sidecar'], File[$config_file]],
  }

}
