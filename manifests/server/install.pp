# puppet::install::server
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::install::server
class puppet::server::install (
    String  $server_package_name = $puppet::params::server_package_name,
    String  $server_version      = $puppet::server_version,
) inherits puppet::params
{
    include puppet::agent::install

    package { $server_package_name:
        ensure  => $server_version,
        require => Package['puppet-agent'],
        alias   => 'puppet-server',
    }
}
