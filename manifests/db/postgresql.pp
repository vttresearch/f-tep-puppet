class ftep::db::postgresql (
  $db_name               = $ftep::globals::ftep_db_name,
  $db_v2_name            = $ftep::globals::ftep_db_v2_name,
  $db_username           = $ftep::globals::ftep_db_username,
  $db_password           = $ftep::globals::ftep_db_password,

  $db_resto_name         = $ftep::globals::ftep_db_resto_name,
  $db_resto_username     = $ftep::globals::ftep_db_resto_username,
  $db_resto_password     = $ftep::globals::ftep_db_resto_password,
  $db_resto_su_username  = $ftep::globals::ftep_db_resto_su_username,
  $db_resto_su_password  = $ftep::globals::ftep_db_resto_su_password,

  $db_zoo_name           = $ftep::globals::ftep_db_zoo_name,
  $db_zoo_username       = $ftep::globals::ftep_db_zoo_username,
  $db_zoo_password       = $ftep::globals::ftep_db_zoo_password,
) {

  if $facts['os']['family'] == 'RedHat' {
    # EPEL is required for the postgis extensions
    require ::epel
  }

  if $ftep::db::trust_local_network {
    $acls = [
      "host ${db_name} ${db_username} samenet md5",
      "host ${db_v2_name} ${db_username} samenet md5",
      "host ${db_v2_name} ${ftep::globals::proxy_dbd_username} samenet md5",
      "host ${db_resto_name} ${db_resto_username} samenet md5",
      "host ${db_resto_name} ${db_resto_su_username} samenet md5",
      "host ${db_zoo_name} ${db_zoo_username} samenet md5",
    ]
  } else {
    $acls = [
      "host ${db_name} ${db_username} ${ftep::globals::wps_hostname} md5",
      "host ${db_name} ${db_username} ${ftep::globals::drupal_hostname} md5",
      "host ${db_name} ${db_username} ${ftep::globals::server_hostname} md5",
      # Access to v2 db only required for f-tep-server and proxy
      "host ${db_v2_name} ${db_username} ${ftep::globals::server_hostname} md5",
      "host ${db_v2_name} ${ftep::globals::proxy_dbd_username} ${ftep::globals::proxy_hostname} md5",
      # Access to resto db only required for ftep-resto
      "host ${db_resto_name} ${db_resto_username} ${ftep::globals::resto_hostname} md5",
      "host ${db_resto_name} ${db_resto_su_username} ${ftep::globals::resto_hostname} md5",
      # Access to zoo db only required for f-tep-wps
      "host ${db_zoo_name} ${db_zoo_username} ${ftep::globals::wps_hostname} md5",
    ]
  }

  # We have to control the package version
  class { ::postgresql::globals:
    manage_package_repo => true,
    version             => '10',
    postgis_version     => '2.4',
  } ->
  class { ::postgresql::server:
    ipv4acls         => $acls,
    listen_addresses => '*',
  }
  class { ::postgresql::server::postgis: }
  class { ::postgresql::server::contrib: }

  ::postgresql::server::db { 'ftepdb':
    dbname   => $db_name,
    user     => $db_username,
    password => postgresql_password($db_username, $db_password),
    grant    => 'ALL',
  }
  ::postgresql::server::db { 'ftepdb_v2':
    dbname   => $db_v2_name,
    user     => $db_username,
    password => postgresql_password($db_username, $db_password),
    grant    => 'ALL',
  }
  ::postgresql::server::db { 'ftepdb_resto':
    dbname   => $db_resto_name,
    user     => $db_resto_username,
    password => postgresql_password($db_resto_username, $db_resto_password),
    grant    => 'ALL',
  }
  ::postgresql::server::role { 'ftepdb_resto_admin':
    username      => $db_resto_su_username,
    password_hash => postgresql_password($db_resto_su_username, $db_resto_su_password),
    db            => $db_resto_name,
    createdb      => false,
    superuser     => true,
    require       => Postgresql::Server::Db['ftepdb_resto'],
  }
  ::postgresql::server::db { 'ftepdb_zoo':
    dbname   => $db_zoo_name,
    user     => $db_zoo_username,
    password => postgresql_password($db_zoo_username, $db_zoo_password),
    grant    => 'ALL',
  }
  ::postgresql::server::role { 'ftepdb_apireader':
    username      => $ftep::globals::proxy_dbd_username,
    password_hash => postgresql_password($ftep::globals::proxy_dbd_username, $ftep::globals::proxy_dbd_password),
    require       => Postgresql::Server::Db['ftepdb_v2']
  }
  ::postgresql::server::table_grant { 'ftepdb_apireader api_keys read permission':
    db        => $db_v2_name,
    table     => $ftep::globals::proxy_dbd_keys_table,
    privilege => 'SELECT',
    role      => $ftep::globals::proxy_dbd_username,
    require   => Postgresql::Server::Role['ftepdb_apireader']
  }
  ::postgresql::server::table_grant { 'ftepdb_apireader users read permission':
    db        => $db_v2_name,
    table     => $ftep::globals::proxy_dbd_users_table,
    privilege => 'SELECT',
    role      => $ftep::globals::proxy_dbd_username,
    require   => Postgresql::Server::Role['ftepdb_apireader']
  }
  ::postgresql::server::grant { 'ftepdb_apireader db connect':
    privilege => 'CONNECT',
    db        => $db_v2_name,
    role      => $ftep::globals::proxy_dbd_username,
    require   => Postgresql::Server::Role['ftepdb_apireader']
  }

}