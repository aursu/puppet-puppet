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
class puppet::server::ca::allow (
  String $server = $puppet::server,
  Optional[String] $ca_server = undef,
) {
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
  }

  # Forbidden request: puppet1.domain.tld(192.168.0.1) access to /puppet-ca/v1/certificate_statuses/any_key
  # (method :get) (authenticated: true) denied by rule 'puppetlabs cert status'.
  puppet_auth_rule { 'puppetlabs cert status':
    ensure               => present,
    match_request_path   => '/puppet-ca/v1/certificate_status',
    match_request_type   => path,
    match_request_method => [get, put, delete],
    allow                => [{ 'extensions' => { 'pp_cli_auth' => true } }, $server] + $ca_server_allow,
  }
}
