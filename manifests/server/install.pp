# puppet::install::server
#
# Puppet server package installation
#
# @summary Puppet server package installation
#
# @param server_package_name
# @param version
#   puppetserver package version or one of puppet Package resource ensure
#   parameter values (latest, installed, absent)
#
# @example
#   include puppet::install::server
class puppet::server::install (
  String $server_package_name = $puppet::params::server_package_name,
  String $version = $puppet::server_version,
) inherits puppet::params {
  include puppet::agent::install
  include puppet::server::compat

  package { 'puppet-server':
    ensure => $version,
    name   => $server_package_name,
  }

  Class['puppet::agent::install'] -> Package['puppet-server']

  # https://puppet.com/docs/puppetserver/5.3/configuration.html#enabling-jruby-9k
  # TODO: jruby upgrade
}
