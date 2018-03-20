# puppet::setup
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::setup
class puppet::setup (
    String  $server_name         = $puppet::server,
    Boolean $hosts_update        = $puppet::hosts_update,
    Optional[String]
            $server_ipaddress    = $puppet::server_ipaddress,
    Optional[Array[String]]
            $dns_alt_names       = $puppet::dns_alt_names,
) inherits puppet::params
{
    if $hosts_update and $server_ipaddress {
        host { $server_name:
            ensure       => 'present',
            ip           => $server_ipaddress,
            host_aliases => $dns_alt_names,
        }
    }
}
