class ftep::monitor::telegraf (
  $influx_host        = 'ftep-monitor',
  $influx_port        = '8086',
  $influx_db          = 'ftep',
  $influx_user        = 'ftep_user',
  $influx_pass        = 'ftep_pass',
  $use_default_inputs = true,
) {

  require ::ftep::globals
  require ::epel

  $real_influx_host = pick($influx_host, $ftep::globals::monitor_hostname)
  $real_influx_port = pick($influx_port, $ftep::globals::monitor_data_port)

  class { '::telegraf':
    hostname => $::hostname,
    outputs  => {
      'influxdb' => {
        'urls'     => [ "http://${real_influx_host}:${real_influx_port}" ],
        'database' => $influx_db,
        'username' => $influx_user,
        'password' => $influx_pass,
      }
    }
  }

  if $use_default_inputs {
    telegraf::input { 'cpu':
      options => {
        percpu   => true,
        totalcpu => true,
      }
    }

    $default_inputs = ['mem', 'io', 'net', 'disk', 'swap', 'system']
    $default_inputs.each | String $input| {
      telegraf::input { $input: }
    }
  }

  $telegraf_inputs = lookup('ftep::monitor::telegraf::inputs', {
    'value_type'    => Hash,
    'default_value' => {}
  })

  ensure_resources(telegraf::input, $telegraf_inputs)

}
