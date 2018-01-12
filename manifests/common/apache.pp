class ftep::common::apache {

  class { ::apache:
    default_vhost => false,
  }

  ::apache::namevirtualhost { '*:80': }

  if $facts['selinux'] {
    ::selinux::port { 'php-fpm':
      seltype  => 'http_port_t',
      port     => 9000,
      protocol => 'tcp'
    }

    ::selinux::port { 'f-tep-server':
      seltype  => 'http_port_t',
      port     => $ftep::globals::server_application_port,
      protocol => 'tcp'
    }

    ::selinux::port { 'f-tep-worker':
      seltype  => 'http_port_t',
      port     => $ftep::globals::worker_application_port,
      protocol => 'tcp'
    }

    ::selinux::port { 'grafana':
      seltype  => 'http_port_t',
      port     => $ftep::globals::grafana_port,
      protocol => 'tcp'
    }

    ::selinux::port { 'graylog':
      seltype  => 'http_port_t',
      port     => $ftep::globals::graylog_port,
      protocol => 'tcp'
    }
  }

}
