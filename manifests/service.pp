# puppet::service
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::service
class puppet::service (
    String  $service_name           = $puppet::params::service_name,
    String  $server_service_ensure  = $puppet::server_service_ensure,
    Boolean $server_service_enable  = $puppet::server_service_enable,
) inherits puppet::params
{
    include puppet::install::server

    service { $service_name:
        ensure  => $server_service_ensure,
        enable  => $server_service_enable,
        require => Package['puppet-server'],
        alias   => 'puppet-server',
    }
}