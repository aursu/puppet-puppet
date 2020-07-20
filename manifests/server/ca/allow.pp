# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::server::ca::allow
class puppet::server::ca::allow (
  Boolean $puppet_master = true,
  String  $server        = $puppet::server,
  Optional[String]
          $ca_server     = undef,
){
  # https://blog.example42.com/2018/10/08/puppet6-ca-upgrading/
  if $puppet_master {
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
      allow                => [{ 'extensions' => {'pp_cli_auth' => true}}, $server] + $ca_server_allow,
    }
  }
}
