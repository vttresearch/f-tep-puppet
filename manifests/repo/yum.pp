# F-TEP package repository
class ftep::repo::yum {
  ensure_resource(yumrepo, 'ftep', {
    baseurl  => $ftep::repo::location,
    enabled  => 1,
    gpgcheck => 0,
  })

  Yumrepo['ftep'] -> Package<|tag == 'ftep'|>
}