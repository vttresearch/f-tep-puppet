define ftep::logging::log4j2 (
  String $ftep_component,
  String $log_level               = 'info',
  String $config_file             = $name,
  Boolean $is_spring_context      = true,

  Boolean $enable_console         = false,

  Boolean $enable_file            = true,
  String $log_dir                 = '/var/log/f-tep',
  String $log_file                = "${log_dir}/${ftep_component}.log",
  String $log_file_pattern        = "${log_dir}//${ftep_component}-%d{yyyyMMdd}-%i.log.gz",

  Boolean $enable_graylog         = $ftep::globals::enable_log4j2_graylog,
  String $graylog_server          = $ftep::globals::monitor_hostname,
  String $graylog_protocol        = 'TCP',
  Integer $graylog_port           = $ftep::globals::graylog_gelf_tcp_port,
  String $graylog_source_hostname = $trusted['certname'],
) {

  ensure_resource(file, $log_dir, {
    ensure => 'directory',
    owner  => 'ftep',
    group  => 'ftep',
  })

  file { $config_file:
    ensure  => 'present',
    owner   => 'ftep',
    group   => 'ftep',
    content => epp('ftep/logging/log4j2.xml.epp', {
      'ftep_component'          => $ftep_component,
      'log_level'               => $log_level,
      'is_spring_context'       => $is_spring_context,
      'enable_console'          => $enable_console,
      'enable_file'             => $enable_file,
      'log_file'                => $log_file,
      'log_file_pattern'        => $log_file_pattern,
      'log_rollover_size'       => '10 MB',
      'enable_graylog'          => $enable_graylog,
      'graylog_server'          => $graylog_server,
      'graylog_protocol'        => $graylog_protocol,
      'graylog_port'            => $graylog_port,
      'graylog_source_hostname' => $graylog_source_hostname
    }),
    require => File[$log_dir],
  }

}