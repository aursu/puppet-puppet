# @summary Adjust Puppet auth.conf to allow 'puppetserver ca' command
#
# Adjust Puppet auth.conf to allow 'puppetserver ca' command
#
# @example
#   include puppet::server::ca::allow
#
# @param server
# @param ca_server
#
# @param allow_header_cert_info
#   Whether Puppet Server takes the client's identity from `X-Client-*` request
#   headers instead of the TLS client certificate. Left `undef` the setting is
#   not managed at all, which is the right default for a server that terminates
#   its own TLS.
#
#   ⚠ Set this true only where a proxy terminates TLS *and* Puppet Server is
#   unreachable except through that proxy - see `puppet::nginx` and
#   `puppet::config::webserver::tls_offload`. With it enabled, anything that can
#   open a connection to Puppet Server can assert any identity, including the
#   CLI-auth extension, so the loopback binding stops being hygiene and becomes
#   the control that holds the whole thing up.
#
# @param restrict_csr_read
#   Require authorisation to *read* certificate requests, while leaving the
#   ability to *submit* one open. Defaults to `false`, which preserves the rule
#   Puppet Server ships.
#
#   The packaged `puppetlabs csr` rule allows both `get` and `put` on
#   `/puppet-ca/v1/certificate_request` unauthenticated. `put` has to stay that
#   way - a node enrolling has no certificate yet, so requiring one would make
#   enrolment impossible. `get` is different: it returns a pending certificate
#   request, and nothing in normal operation reads it (`puppetserver ca list`
#   uses `/certificate_statuses`). Enabling this narrows the packaged rule to
#   `put` and adds a `get` rule restricted the same way the certificate-status
#   rules above are - the CLI-auth extension plus the server itself.
#
class puppet::server::ca::allow (
  String $server = $puppet::server,
  Optional[String] $ca_server = undef,
  Boolean $restrict_csr_read = false,
  Optional[Boolean] $allow_header_cert_info = undef,
) {
  include puppet::server::install

  # https://blog.example42.com/2018/10/08/puppet6-ca-upgrading/
  if $ca_server {
    $ca_server_allow = [$ca_server]
  }
  else {
    $ca_server_allow = []
  }

  # puppetserver ca list
  # Error:
  #     code: 403
  #     body: Forbidden request: /puppet-ca/v1/certificate_statuses/any_key (method :get)
  puppet_auth_rule { 'puppetlabs cert statuses':
    ensure               => present,
    match_request_path   => '/puppet-ca/v1/certificate_statuses',
    match_request_type   => path,
    match_request_method => get,
    allow                => [{ 'extensions' => { 'pp_cli_auth' => true } }, $server] + $ca_server_allow,
    require              => Class['puppet::server::install'],
  }

  # Forbidden request: puppet1.domain.tld(192.168.0.1) access to /puppet-ca/v1/certificate_statuses/any_key
  # (method :get) (authenticated: true) denied by rule 'puppetlabs cert status'.
  puppet_auth_rule { 'puppetlabs cert status':
    ensure               => present,
    match_request_path   => '/puppet-ca/v1/certificate_status',
    match_request_type   => path,
    match_request_method => [get, put, delete],
    allow                => [{ 'extensions' => { 'pp_cli_auth' => true } }, $server] + $ca_server_allow,
    require              => Class['puppet::server::install'],
  }

  if $allow_header_cert_info =~ NotUndef {
    puppet_auth_setting { 'allow-header-cert-info':
      ensure  => present,
      value   => $allow_header_cert_info,
      require => Class['puppet::server::install'],
    }
  }

  if $restrict_csr_read {
    # Rewrites the rule Puppet Server ships under the same name, narrowing it to
    # the half that has to stay open. Submitting a CSR is how a node enrols, so
    # it cannot require a certificate; the type forbids combining
    # allow_unauthenticated with allow/deny, which matches that intent.
    puppet_auth_rule { 'puppetlabs csr':
      ensure                => present,
      match_request_path    => '/puppet-ca/v1/certificate_request',
      match_request_type    => path,
      match_request_method  => put,
      allow_unauthenticated => true,
      require               => Class['puppet::server::install'],
    }

    # Reading a pending request is a different matter: it discloses a CSR to
    # whoever asks, and no routine operation needs it.
    puppet_auth_rule { 'puppetlabs csr read':
      ensure               => present,
      match_request_path   => '/puppet-ca/v1/certificate_request',
      match_request_type   => path,
      match_request_method => get,
      allow                => [{ 'extensions' => { 'pp_cli_auth' => true } }, $server] + $ca_server_allow,
      require              => Class['puppet::server::install'],
    }
  }
}
