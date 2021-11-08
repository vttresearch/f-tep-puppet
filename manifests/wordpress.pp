# WARNING: This class will likely conflict with other PHP applications.
# Do not apply it to the same node as Drupal or Resto.

class ftep::wordpress (
  # $drupal_site      = 'forestry-tep.eo.esa.int',
  $www_path                      = '/var/www/html/wordpress',
  $www_user                      = 'www-data',

  $db_name                       = undef,
  $db_user                       = undef,
  $db_pass                       = undef,
  $db_port                       = '5432',
  $db_driver                     = 'pgsql',
  $db_prefix                     = '',

  $php_version                   = '7.4',
  $php_extensions                = {
    "curl"      => {},
    "dom"       => {},
    "exif"      => {},
    "fileinfo"  => {},
    "json"      => {},
    "mbstring"  => {},
    "mysqli"    => {},
    "imagick"   => {},
    "xml"       => {},
    "zip"       => {},
    "gd"        => {},
    "iconv"     => {},
    "simplexml" => {},
    "xmlreader" => {},
  },

  $wp_cli_source_url             = 'https://github.com/wp-cli/wp-cli/releases/download/v2.4.0/wp-cli-2.4.0.phar',
  $wp_cli_source_checksum_type   = 'sha512',
  $wp_cli_source_checksum        =
  '4049c7e45e14276a70a41c3b0864be7a6a8cfa8ea65ebac8b184a4f503a91baa1a0d29260d03248bc74aef70729824330fb6b396336172a624332e16f64e37ef'
  ,
  $wp_cli_source_checksum_verify = true,
  $wp_cli_bin                    = '/usr/local/bin/wp',

  $wordpress_version             = '5.6.1',
  $wordpress_locale              = 'en_GB',
  $url                           = undef,
  $wordpress_title               = 'F-TEP',
  $wordpress_admin_user          = 'wpadmin',
  $wordpress_admin_password      = 'wpadminpass',
  $wordpress_admin_email         = 'wpadmin@example.com',
) {

  require ::ftep::globals

  contain ::ftep::common::apache
  include ::apache::mod::proxy
  include ::apache::mod::proxy_fcgi
  include ::apache::mod::rewrite
  include ::mysql::server

  $real_db_name = pick($db_name, $::ftep::globals::wordpress_db_name)
  $real_db_user = pick($db_user, $::ftep::globals::wordpress_db_username)
  $real_db_pass = pick($db_pass, $::ftep::globals::wordpress_db_password)
  $real_url = pick($url, $ftep::globals::base_url)

  mysql_user { "${real_db_user}@localhost":
    ensure        => 'present',
    password_hash => mysql::password($real_db_pass)
  }

  mysql_grant { "${real_db_user}@localhost/${real_db_name}.*":
    ensure     => 'present',
    user       => "${real_db_user}@localhost",
    privileges => ['ALL'],
    table      => "${real_db_name}.*",
    require    => [
      Mysql_user["${real_db_user}@localhost"],
    ],
  }

  class { '::php::globals':
    php_version => $php_version,
  } ->
  class { '::php':
    extensions => $php_extensions,
  }

  file { $wp_cli_bin:
    ensure         => 'file',
    source         => $wp_cli_source_url,
    checksum       => $wp_cli_source_checksum_type,
    checksum_value => $wp_cli_source_checksum,
    owner          => 'root',
    group          => 'root',
    mode           => '0755',
    require        => [Class['::php']],
  }

  file { $www_path:
    ensure  => 'directory',
    owner   => $www_user,
    group   => $www_user,
    mode    => '0755',
    require => [Class['::apache']],
  }

  $wp = "${wp_cli_bin} --path=${www_path}"

  $wp_download_args = join([
    'core',
    'download',
    "--version=${wordpress_version}",
    "--locale=${wordpress_locale}"
  ], ' ')
  exec { 'wp-download':
    command => "${wp} ${wp_download_args}",
    user    => $www_user,
    group   => $www_user,
    require => [File[$wp_cli_bin], File[$www_path]],
    creates => "${www_path}/index.php"
  }

  $wp_config_create_args = join([
    "config",
    "create",
    "--dbname=${real_db_name}",
    "--dbuser=${real_db_user}",
    "--dbpass=${real_db_pass}",
    "--dbprefix=${db_prefix}",
  ], ' ')
  exec { 'wp-config-create':
    command => "${wp} ${wp_config_create_args}",
    user    => $www_user,
    group   => $www_user,
    require => [
      Exec['wp-download'],
      Mysql_user["${real_db_user}@localhost"],
      Mysql_grant["${real_db_user}@localhost/${real_db_name}.*"]
    ],
    creates => "${www_path}/wp-config.php"
  }

  $wp_db_create_args = join([
    "db",
    "create",
  ], ' ')
  exec { 'wp-db-create':
    command => "${wp} ${wp_db_create_args} && touch ${www_path}/.dbinit",
    user    => $www_user,
    group   => $www_user,
    require => [Exec['wp-config-create']],
    creates => "${www_path}/.dbinit",
  }

  $wp_core_install_args = join([
    "core",
    "install",
    "--url=${real_url}",
    "--title=\"${title}\"",
    "--admin_user=${wordpress_admin_user}",
    "--admin_password=${wordpress_admin_password}",
    "--admin_email=${wordpress_admin_email}",
  ], ' ')
  exec { 'wp-install':
    command => "${wp} ${wp_core_install_args}",
    user    => $www_user,
    group   => $www_user,
    require => [Exec['wp-db-create']],

    unless  => ["${wp_cli_bin} --path=${www_path} core is-installed"]
  }

  ::php::apache_vhost { 'wp_vhost':
    vhost          => 'ftep-wordpress',
    docroot        => $www_path,
    port           => 80,
    default_vhost  => true,
    fastcgi_socket => "fcgi://127.0.0.1:9000/${www_path}/\$1",
    require        => [Class['::apache'], Exec['wp-install']],
  }

}
