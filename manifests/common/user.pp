class ftep::common::user (
  $user  = undef,
  $group = undef,
  $home  = '/home/ftep'
) {

  $real_user = pick($user, $ftep::globals::user)
  $real_group = pick($group, $ftep::globals::group)

  group { $real_group:
    ensure => present,
  }

  user { $real_user:
    ensure     => present,
    gid        => $real_group,
    managehome => true,
    home       => $home,
    shell      => '/bin/bash',
    system     => true,
    require    => Group[$real_group],
  }

  file { $home:
    ensure  => directory,
    owner   => $real_user,
    require => User[$real_user];
  }

}