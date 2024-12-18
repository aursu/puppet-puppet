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
# @param version
#
class puppet::agent::install (
  String $agent_package_name  = $puppet::params::agent_package_name,
  String $version = $puppet::agent_version,
) inherits puppet::params {
  include puppet::repo

  case $facts['os']['family'] {
    'Debian': {
      $package_ensure = $version
    }
    # default is RPM based systems
    default: {
      $version_data  = split($version, '[-]')
      $major_version = $version_data[0]
      $build_version = $version_data[1]

      if $build_version or $version in ['present', 'absent', 'purged', 'installed', 'latest'] {
        $package_ensure = $version
      }
      else {
        $package_ensure = "${major_version}-${puppet::params::package_build}"
      }
    }
  }

  package { 'puppet-agent':
    ensure => $package_ensure,
    name   => $agent_package_name,
  }

  Class['puppet::repo'] -> Package['puppet-agent']
}
