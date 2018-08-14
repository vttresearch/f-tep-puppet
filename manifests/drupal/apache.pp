class ftep::drupal::apache (
  $site_path
) {

  require ::ftep::globals

  contain ::ftep::common::apache

  include ::apache::mod::proxy_http
  include ::apache::mod::rewrite
  include ::apache::mod::proxy
  include ::apache::mod::proxy_fcgi

  ::apache::vhost { 'ftep-drupal':
    port             => '80',
    servername       => 'ftep-drupal',
    docroot          => "${site_path}",
    override         => ['All'],
    directoryindex   => '/index.php index.php',
    proxy_pass_match => [
      {
        'path' => '^/(.*\.php(/.*)?)$',
        'url'  => "fcgi://127.0.0.1:9000${site_path}/\$1"
      }
    ],
    rewrites         => [
      { rewrite_rule => [
        '^/api/(.*) /api.php?q=api/$1 [L,PT,QSA]',
        '^/secure/api/(.*) /api.php?q=api/$1 [L,PT,QSA]'
      ] },
    ]
  }

  if $facts['selinux'] {
    ensure_resource(::selinux::boolean, 'httpd_can_network_connect_db', { ensure => true })
  }

}