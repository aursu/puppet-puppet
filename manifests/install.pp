# puppet::install
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::install
class puppet::install (
    String $agent_package_name  = $puppet::params::agent_package_name,
    String $puppet_agent_ensure = $puppet::puppet_agent_ensure,
) inherits puppet::params
{
    include puppet::repo

    package { 'puppet-agent':
        ensure  => 'latest',
        name    => $agent_package_name,
        require => Package['puppet5-repository'],
    }
}

