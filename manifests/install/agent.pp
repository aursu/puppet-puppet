# puppet::install::agent
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::install::agent
class puppet::install::agent (
    String  $agent_package_name  = $puppet::params::agent_package_name,
    String  $agent_version       = $puppet::agent_version,
) inherits puppet::params
{
    include puppet::repo

    package { 'puppet-agent':
        ensure  => $agent_version,
        name    => $agent_package_name,
        require => Package['puppet5-repository'],
    }
}
