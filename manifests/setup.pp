# puppet::setup
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::setup
class puppet::setup (
    Boolean $puppet_master       = $puppet::master,
    String  $server_name         = $puppet::server,
    Boolean $hosts_update        = $puppet::hosts_update,
    Optional[String]
            $server_ipaddress    = $puppet::server_ipaddress,
    Optional[Array[String]]
            $dns_alt_names       = $puppet::dns_alt_names,
    Stdlib::Absolutepath
            $r10k_path           = $puppet::params::r10k_path,
    Boolean $r10k                = $puppet::r10k_deployment,
) inherits puppet::params
{
    if $hosts_update and $server_ipaddress {
        host { $server_name:
            ensure       => 'present',
            ip           => $server_ipaddress,
            host_aliases => $dns_alt_names,
        }
    }

    if $puppet_master and $r10k {
        exec { 'environment-setup':
            command => "${r10k_path} deploy environment -p",
            require => Exec['r10k-installation'],
        }
    }
}
