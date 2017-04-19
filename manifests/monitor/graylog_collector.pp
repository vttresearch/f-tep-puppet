class ftep::monitor::graylog_collector (
  $enable_syslog_collector = true,
  $enable_apache_collector = false,
  $graylog_api_url         = undef,
  $graylog_server          = undef,
  $graylog_gelf_tcp_port   = undef,
) {

  require ::ftep::globals

  $real_graylog_api_url = pick($graylog_api_url, "${ftep::globals::base_url}${ftep::globals::graylog_api_path}")
  $real_graylog_server = pick($graylog_server, $ftep::globals::monitor_hostname)
  $real_graylog_gelf_tcp_port = pick($graylog_gelf_tcp_port, $ftep::globals::graylog_gelf_tcp_port)

  ensure_packages(['graylog-connector'], {
    ensure => 'present',
  })

  file { '/etc/graylog/collector/collector.conf':
    ensure  => present,
    mode    => '640',
    content => epp('ftep/graylog-collector/collector.conf.epp', {
      'enable_syslog_collector' => $enable_syslog_collector,
      'enable_apache_collector' => $enable_apache_collector,
      'graylog_api_url'         => $real_graylog_api_url,
      'graylog_server'          => $real_graylog_server,
      'graylog_gelf_tcp_port'   => $real_graylog_gelf_tcp_port,
    }),
    require => Package['graylog-connector'],
    notify  => Service['graylog-collector'],
  }

  service { 'graylog-collector':
    ensure => 'running',
    enable => true
  }

}
