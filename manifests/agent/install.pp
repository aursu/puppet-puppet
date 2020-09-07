# puppet::agent::install
#
# Puppet 5 agent installation
#
# @summary Puppet 5 agent installation
#
# @example
#   include puppet::agent::install
class puppet::agent::install (
    String  $agent_package_name  = $puppet::params::agent_package_name,
    String  $agent_version       = $puppet::agent_version,
) inherits puppet::params
{
    include puppet::repo

    package { $agent_package_name:
        ensure  => $agent_version,
        require => Package['puppet5-repository'],
        alias   => 'puppet-agent',
    }
}
