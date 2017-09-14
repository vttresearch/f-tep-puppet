define ftep::monitor::telegraf_jolokia_input (
  String $management_context_path,
  Integer $management_port,
) {
  if $management_context_path =~ /\/$/ {
    $jolokia_context = "${management_context_path}jolokia/"
  } else {
    $jolokia_context = "${management_context_path}/jolokia/"
  }

  $input_name = "jolokia_${name}"

  telegraf::input { $input_name:
    plugin_type => 'jolokia',
    options     => {
      context => $jolokia_context,
    },
    sections    => {
      "jolokia.servers" => {
        'name' => $name,
        'host' => '127.0.0.1',
        'port' => "${management_port}",
      },
      "jolokia.metrics" => {
        'name'      => $name,
        'mbean'     => 'org.springframework.boot:name=metricsEndpoint,type=Endpoint',
        'attribute' => 'Data',
      }
    }
  }
}