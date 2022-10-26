# puppet::agent::install
#
# Puppet 5 agent installation
#
# @summary Puppet 5 agent installation
#
# @example
#   include puppet::agent::install
#
# @param agent_package_name
# @param agent_version
#
class puppet::agent::install (
  String $agent_package_name  = $puppet::params::agent_package_name,
  String $agent_version = $puppet::agent_version,
) inherits puppet::params {
  include puppet::repo

  package { 'puppet-agent':
    ensure => $agent_version,
    name   => $agent_package_name,
  }

  Class['puppet::repo'] -> Package['puppet-agent']
}
