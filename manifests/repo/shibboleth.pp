class ftep::repo::shibboleth {
  ensure_resource('yumrepo', 'shibboleth', {
    ensure   => 'present',
    descr    => 'Shibboleth (CentOS_7)',
    baseurl  => 'http://download.opensuse.org/repositories/security:/shibboleth/CentOS_7/',
    enabled  => 1,
    gpgcheck => 1,
    gpgkey   => 'http://download.opensuse.org/repositories/security:/shibboleth/CentOS_7/repodata/repomd.xml.key',
  })
}