class ftep::monitor (
  $enable_grafana  = true,
  $enable_influxdb = true,
  $enable_graylog  = true,
) {

  if $enable_grafana {
    contain ::ftep::monitor::grafana
  }

  if $enable_influxdb {
    contain ::ftep::monitor::influxdb
  }

  if $enable_graylog {
    contain ::ftep::monitor::graylog_server
  }

}
