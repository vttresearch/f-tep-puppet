# F-TEP package repository
class ftep::repo::ftep {
  ensure_resource(yumrepo, 'ftep', {
    ensure   => 'present',
    descr    => 'F-TEP',
    baseurl  => $ftep::repo::location,
    enabled  => 1,
    gpgcheck => 0,
  })
}