# puppet::service
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::service
class puppet::service (
    String  $server_service_ensure  = $puppet::server_service_ensure,
    Boolean $server_service_enable  = $puppet::server_service_enable,
    String  $service_name           = $puppet::params::service_name,
) inherits puppet::params
{
    include puppet::server::install
    include puppet::enc
    include puppet::config

    service { $service_name:
        ensure    => $server_service_ensure,
        enable    => $server_service_enable,
        require   => File['enc-script'],
        subscribe => [
            Package['puppet-server'],
            Class['puppet::config']
        ],
        alias     => 'puppet-server',
    }
}
