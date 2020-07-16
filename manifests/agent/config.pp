# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::agent::config
class puppet::agent::config (
  Stdlib::Fqdn
          $server           = 'puppet',
  String  $node_environment = 'production',
  Boolean $onetime          = true,
  Puppet::TimeUnit
          $runtimeout       = '10m',
)
{
  class { 'puppet::config':
    puppet_master    => false,
    server           => $server,
    node_environment => $node_environment,
    onetime          => $onetime,
    runtimeout       => $runtimeout,
  }
}
