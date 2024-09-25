# @summary Configure Puppet Agent settings
#
# Configure Puppet Agent settings
#
# @example
#   include puppet::agent::config
#
# @param server
# @param node_environment
# @param onetime
# @param runtimeout
# @param ca_server
# @param certname
#
class puppet::agent::config (
  Stdlib::Fqdn $server = 'puppet',
  String  $node_environment = 'production',
  Boolean $onetime = true,
  Puppet::TimeUnit $runtimeout = '10m',
  Optional[String] $ca_server = undef,
  Optional[String] $certname = undef,
) {
  $static_certname = $certname ? {
    String  => true,
    default => false,
  }

  class { 'puppet::config':
    server_mode      => false,
    server           => $server,
    ca_server        => $ca_server,
    node_environment => $node_environment,
    onetime          => $onetime,
    runtimeout       => $runtimeout,
    static_certname  => $static_certname,
    certname         => $certname,
  }
}
