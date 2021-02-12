class ftep::proxy::shibboleth (
  $service_ensure                   = 'running',
  $service_enable                   = true,

  $config_dir                       = '/etc/shibboleth',
  $metadata_subdir                  = 'metadata',

  $clock_skew                       = 180,

  $sp_id                            = 'https://forestry-tep.eo.esa.int/shibboleth',
  $home_url                         = 'https://f-tep.com/',
  $app_defaults_signing             = 'true',
  $app_defaults_encryption          = 'false',
  $app_defaults_remote_user         = 'Eosso-Person-commonName',
  $app_defaults_extra_attrs         = {},
  $session_lifetime                 = 7200,
  $session_timeout                  = 3600,
  $session_check_address            = false,
  $session_consistent_address       = false,
  $support_contact                  = 'eo-gpod@esa.int',
  $idp_id                           = 'eoiam-idp.eo.esa.int',
  $idp_signature_digest,
  $idp_signature_value,
  $redirect_errors                  = 'https://eoiam-idp.eo.esa.int/authenticationendpoint/auth_error.jsp',
  $sp_cert                          = undef,
  $sp_key                           = undef,
  $sp_assertion_consumer_services   = [
    { 'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
      'location' => 'https://f-tep.com/Shibboleth.sso/SAML2/POST' },
  ],
  $sp_slo_services                  = [{
    'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
    'location' => 'https://f-tep.com/Shibboleth.sso/SLO/Redirect'
  }],
  $sp_name_id_formats               = ['urn:oasis:names:tc:SAML:2.0:nameid-format:transient'],
  $org_name                         = 'f-tep',
  $org_display_name                 = 'Forestry TEP',
  $attribute_map                    = [
    {
      'name'        => 'urn:mace:dir:attribute-def:cn',
      'id'          => 'Eosso-Person-commonName',
      'name_format' => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic'
    },
    {
      'name'        => 'urn:mace:dir:attribute-def:mail',
      'id'          => 'Eosso-Person-Email',
      'name_format' => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic'
    },
    {
      'name'        => 'urn:mace:dir:attribute-def:organization',
      'id'          => 'Eosso-Person-Organization',
      'name_format' => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic'
    },
    {
      'name'        => 'urn:mace:dir:attribute-def:countryCode',
      'id'          => 'Eosso-Person-Country',
      'name_format' => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic'
    },
  ],
  $idp_cert,
  $idp_artifact_resolution_services = [
    { 'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
      'location' => 'https://eoiam-idp.eo.esa.int:443/samlartresolve' },
  ],
  $idp_slo_services                 = [
    { 'binding'           => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
      'location'          => 'https://eoiam-idp.eo.esa.int/samlsso',
      'response_location' => 'https://eoiam-idp.eo.esa.int/samlsso'
    },
    { 'binding'           => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
      'location'          => 'https://eoiam-idp.eo.esa.int/samlsso',
      'response_location' => 'https://eoiam-idp.eo.esa.int/samlsso'
    },
    { 'binding'           => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
      'location'          => 'https://eoiam-idp.eo.esa.int/samlsso',
      'response_location' => 'https://eoiam-idp.eo.esa.int/samlsso'
    }
  ],
  $idp_name_id_formats              = [
    'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified',
  ],
  $idp_sso_services                 = [
    { 'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
      'location' => 'https://eoiam-idp.eo.esa.int/samlsso' },
    { 'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
      'location' => 'https://eoiam-idp.eo.esa.int/samlsso' },
  ],
  $idp_keyname                      = "defcreds",
  $shibboleth2_xml_extra_content    = "",
) {

  require ::ftep::repo::shibboleth

  # mod_shib with the upstream shibboleth package must use a custom path
  class { ::apache::mod::shib:
    suppress_warning => true,
    mod_full_path    => '/usr/lib64/shibboleth/mod_shib_24.so',
    require          => Package['shibboleth'],
  }

  ensure_packages(['shibboleth'], {
    ensure  => latest,
    tag     => 'shibboleth',
    require => Yumrepo['shibboleth'],
  })

  ensure_resource(service, 'shibd', {
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['shibboleth'],
  })

  # Re-use the key/certificate from the shared config
  file { "${config_dir}/sp-cert.crt":
    ensure  => present,
    mode    => '0644',
    owner   => 'shibd',
    group   => 'shibd',
    content => pick($sp_cert, $ftep::proxy::tls_cert),
    require => Package['shibboleth'],
    notify  => Service['shibd'],
  }

  file { "${config_dir}/sp-key.key":
    ensure  => present,
    mode    => '0600',
    owner   => 'shibd',
    group   => 'shibd',
    content => pick($sp_key, $ftep::proxy::tls_key),
    require => Package['shibboleth'],
    notify  => Service['shibd'],
  }

  file { "${config_dir}/shibboleth2.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('ftep/proxy/shibboleth/shibboleth2.xml.epp', {
      'clock_skew'                 => $clock_skew,
      'sp_id'                      => $sp_id,
      'home_url'                   => $home_url,
      'app_defaults_signing'       => $app_defaults_signing,
      'app_defaults_encryption'    => $app_defaults_encryption,
      'app_defaults_remote_user'   => $app_defaults_remote_user,
      'app_defaults_extra_attrs'   => $app_defaults_extra_attrs,
      'session_lifetime'           => $session_lifetime,
      'session_timeout'            => $session_timeout,
      'session_check_address'      => $session_check_address,
      'session_consistent_address' => $session_consistent_address,
      'support_contact'            => $support_contact,
      'idp_id'                     => $idp_id,
      'metadata_subdir'            => $metadata_subdir,
      'sp_key'                     => "${config_dir}/sp-key.key",
      'sp_cert'                    => "${config_dir}/sp-cert.crt",
      'idp_keyname'                => $idp_keyname,
      'redirect_errors'            => $redirect_errors,
      'extra_content'              => $shibboleth2_xml_extra_content,
    }),
    require => Package['shibboleth'],
    notify  => Service['shibd'],
  }

  file { "${config_dir}/attribute-policy.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('ftep/proxy/shibboleth/attribute-policy.xml.epp', {}),
    require => Package['shibboleth'],
  }

  file { "${config_dir}/attribute-map.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('ftep/proxy/shibboleth/attribute-map.xml.epp', {
      'attributes' => $attribute_map,
    }),
    require => Package['shibboleth'],
  }

  file { "${config_dir}/globalLogout.html":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('ftep/proxy/shibboleth/globalLogout.html.epp', {
      'logout_refresh_url' => $home_url
    }),
    require => Package['shibboleth'],
  }

  file { "${config_dir}/localLogout.html":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('ftep/proxy/shibboleth/localLogout.html.epp', {
      'logout_refresh_url' => $home_url
    }),
    require => Package['shibboleth'],
  }

  file { "${config_dir}/${metadata_subdir}":
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['shibboleth'],
  }

  file { "${config_dir}/${metadata_subdir}/sp-metadata.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('ftep/proxy/shibboleth/sp-metadata.xml.epp', {
      'sp_id'                       => $sp_id,
      'sp_cert'                     => $ftep::proxy::tls_cert,
      'assertion_consumer_services' => $sp_assertion_consumer_services,
      'slo_services'                => $sp_slo_services,
      'name_id_formats'             => $sp_name_id_formats,
      'org_name'                    => $org_name,
      'org_display_name'            => $org_display_name,
      'org_url'                     => $home_url,
    }),
    require => File["${config_dir}/${metadata_subdir}"],
  }

  file { "${config_dir}/${metadata_subdir}/idp-metadata.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('ftep/proxy/shibboleth/idp-metadata.xml.epp', {
      'idp_id'                       => $idp_id,
      'idp_signature_digest'         => $idp_signature_digest,
      'idp_signature_value'          => $idp_signature_value,
      'idp_cert'                     => $idp_cert,
      'artifact_resolution_services' => $idp_artifact_resolution_services,
      'slo_services'                 => $idp_slo_services,
      'sso_services'                 => $idp_sso_services,
      'name_id_formats'              => $idp_name_id_formats,
    }),
    require => File["${config_dir}/${metadata_subdir}"],
  }

}