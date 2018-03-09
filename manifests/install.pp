# puppet::install
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::install
class puppet::install (
    String  $agent_package_name  = $puppet::params::agent_package_name,
    String  $agent_version       = $puppet::agent_version,
    Boolean $puppet_master       = $puppet::master,
    String  $server_package_name = $puppet::params::server_package_name,
    String  $server_version      = $puppet::server_version,
    Boolean $r10k                = $puppet::r10k_deployment,
    String  $r10k_package_name   = $puppet::params::r10k_package_name,
    String  $gem_path            = $puppet::params::gem_path,
    String  $r10k_path           = $puppet::params::r10k_path,
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
            ensure  => $server_version,
            name    => $server_package_name,
            require => Package['puppet-agent'],
        }
    }

    if $r10k_deployment {
        exec { 'r10k-installation':
            command => "${gem_path} install ${r10k_package_name}",
            creates => $r10k_path,
            require => Package['puppet-agent'],
        }
    }
}
