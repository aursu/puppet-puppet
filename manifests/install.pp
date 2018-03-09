# puppet::install
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::install
class puppet::install (
    String  $agent_package_name   = $puppet::params::agent_package_name,
    String  $server_package_name  = $puppet::params::server_package_name,
    String  $puppet_agent_ensure  = $puppet::puppet_agent_ensure,
    String  $puppet_server_ensure = $puppet::puppet_server_ensure,
    Boolean $puppet_master        = $puppet::master,
) inherits puppet::params
{
    include puppet::repo

    package { 'puppet-agent':
        ensure  => 'latest',
        name    => $agent_package_name,
        require => Package['puppet5-repository'],
    }

    if $puppet_master {
        package { 'puppet-server':
            ensure  => $puppet_server_ensure,
            name    => $server_package_name,
            require => Package['puppet-agent'],
        }
    }
}

