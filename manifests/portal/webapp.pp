class ftep::portal::webapp {
  ensure_resource(package, 'f-tep-portal', {
    ensure  => 'latest',
    name    => 'f-tep-portal',
  })
}
