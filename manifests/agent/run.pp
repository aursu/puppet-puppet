# @summary Puppet agent run command
#
# Puppet agent run command
#
# @example
#   include puppet::agent::run
class puppet::agent::run (
  Stdlib::Unixpath
          $puppet_path = $puppet::params::puppet_path,
  String  $options     = '--test',
) inherits puppet::params
{
  # /opt/puppetlabs/puppet/bin/puppet agent --test
  exec { 'puppet-agent-run':
    command => "${puppet_path} agent ${options}",
    returns => [0, 1, 2, 4, 6],
  }
}
