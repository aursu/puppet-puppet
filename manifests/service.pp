# puppet::service
#
# Puppet server service management
#
# @summary Puppet server service management
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
  include puppet::server::ca::allow

  service { 'puppet-server':
    ensure => $server_service_ensure,
    name   => $service_name,
    enable => $server_service_enable,
  }

  Class['puppet::server::install'] ~> Service['puppet-server']
  Class['puppet::config'] ~> Service['puppet-server']
  Class['puppet::server::ca::allow'] ~> Service['puppet-server']
  Class['puppet::enc'] -> Service['puppet-server']
}
