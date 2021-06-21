define ftep::monitor::telegraf_jolokia_input (
  String $management_context_path,
  Integer $management_port,
) {
  if $management_context_path =~ /\/$/ {
    $jolokia_context = "http://127.0.0.1:${management_port}${management_context_path}actuator/jolokia/"
  } else {
    $jolokia_context = "http://127.0.0.1:${management_port}${management_context_path}/actuator/jolokia/"
  }

  $input_name = "jolokia_${name}"

  telegraf::input { $input_name:
    plugin_type => 'jolokia2_agent',
    options     => {
      urls => [$jolokia_context],
    },
    sections    => {
      # "jolokia.servers" => {
      #   'name' => $name,
      #   'host' => '127.0.0.1',
      #   'port' => "${management_port}",
      # },
      "jolokia2_agent.metric" => {
        'name'  => $name,
        'mbean' => 'org.springframework.boot:name=Metrics,type=Endpoint',
        'paths' => ['Data'],
      }
    }
  }
}