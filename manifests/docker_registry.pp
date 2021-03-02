class ftep::docker_registry (
  $registry_docker_image            = 'docker.io/registry:latest',
  $public_port                      = 5000,
  $container_port                   = 5000,
  $container_name                   = 'registry',
  $storage                          = 'filesystem', # filesystem|s3
  $storage_filesystem_rootdirectory = undef,
  $storage_s3_accesskey             = undef,
  $storage_s3_secretkey             = undef,
  $storage_s3_region                = undef,
  $storage_s3_regionendpoint        = undef,
  $storage_s3_bucket                = undef,
  $storage_s3_encrypt               = undef,
  $storage_s3_secure                = undef,
  $default_config                   = {
    'version' => 0.1,
    'log'     => { 'fields' => { 'service' => 'registry' } },
    'storage' => { 'cache' => { 'blobdescriptor' => 'inmemory' } },
    'http'    => { 'addr' => ':5000', 'headers' => { 'X-Content-Type-Options' => ['nosniff'] } },
    'health'  => { 'storagedriver' => { 'enabled' => true, 'interval' => '10s', 'threshold' => 3 } }
  },
  $additional_config                = {
    'storage' => { 'delete' => { 'enabled' => 'true' } }
  },
) {

  require ::ftep::globals

  contain ::ftep::common::datadir
  contain ::ftep::common::user
  contain ::ftep::common::docker

  case $storage {
    'filesystem': {
      $rootdir = pick($storage_filesystem_rootdirectory, "${ftep::common::datadir::data_basedir}/registry")
      $storage_env = {
        'storage' => {
          'filesystem' => {
            'rootdirectory' => '/var/lib/registry'
          }
        }
      }
      $volumes = ["${rootdir}:/var/lib/registry:rw"]
    }
    's3': {
      $storage_env = {
        'storage' => {
          's3' => {
            'accesskey'      => $storage_s3_accesskey,
            'secretkey'      => $storage_s3_secretkey,
            'region'         => $storage_s3_region,
            'regionendpoint' => $storage_s3_regionendpoint,
            'bucket'         => $storage_s3_bucket,
            'encrypt'        => $storage_s3_encrypt,
            'secure'         => $storage_s3_secure,
          }
        }
      }
      $volumes = []
    }
    default: {
      $storage_env = {}
      $volumes = []
    }
  }

  $_config = deep_merge($default_config, $storage_env, $additional_config)

  file { '/etc/docker-registry.yaml':
    ensure  => file,
    content => to_yaml($_config),
  } ->
  ::docker::run { $container_name:
    image   => $registry_docker_image,
    ports   => ["${public_port}:${container_port}"],
    volumes => concat($volumes, ['/etc/docker-registry.yaml:/etc/docker/registry/config.yml:ro']),
  }

}
