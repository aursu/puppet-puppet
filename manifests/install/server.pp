# puppet::install::server
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::install::server
class puppet::install::server (
    String  $server_package_name = $puppet::params::server_package_name,
    String  $server_version      = $puppet::server_version,
) inherits puppet::params
{
    include puppet::install::agent

    package { 'puppet-server':
        ensure  => $server_version,
        name    => $server_package_name,
        require => Package['puppet-agent'],
    }
}
