class ftep::traefik (
  $traefik_docker_image = 'docker.io/traefik:1.7.30',
  $traefik_config_path  = '/var/f-tep/traefik/',
  $traefik_config_file  = '/var/f-tep/traefik/traefik.toml',
  # Ensure ftep::globals::{traefik_user,traefik_password} are updated if this changes
  $traefik_admin_user   = 'fteptraefik:$apr1$dDjBi/fR$3rLrIZG.nLT4/8nL9Mjit0',
  $traefik_admin_port   = undef,
  $traefik_service_port = undef,
) {

  require ::ftep::globals

  file { $traefik_config_path:
    ensure => 'directory',
    owner  => $ftep::globals::user,
    group  => $ftep::globals::group,
  } ->
  file { $traefik_config_file:
    ensure  => 'present',
    owner   => $ftep::globals::user,
    group   => $ftep::globals::group,
    content => epp('ftep/traefik/traefik.toml.epp', {
      'traefik_admin_user'   => $traefik_admin_user,
      'traefik_admin_port'   => pick($traefik_admin_port, $ftep::globals::traefik_admin_port),
      'traefik_service_port' => pick($traefik_service_port, $ftep::globals::traefik_service_port)
    }),
  } ->
  ::docker::run { 'traefik':
    image   => $traefik_docker_image,
    net     => 'host',
    volumes => ["$traefik_config_file:/etc/traefik/traefik.toml"],
  }

}
