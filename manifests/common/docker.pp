class ftep::common::docker (
) {

  require ::ftep::common::user

  class { ::docker:
    docker_users => [$ftep::globals::user],
  }

}