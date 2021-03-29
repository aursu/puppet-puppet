# puppet::repo
#
# Setup Puppet Platform repository
#
# @summary Setup Puppet Platform repository
#
# @example
#   include puppet::repo
class puppet::repo (
    String $package_name        = $puppet::globals::package_name,
    String $package_filename    = $puppet::globals::package_filename,
    String $platform_repository = $puppet::globals::platform_repository,
    String $package_provider    = $puppet::params::package_provider,
) inherits puppet::globals
{
  exec { 'puppet-release':
    command => "curl ${platform_repository} -s -o ${package_filename}",
    cwd     => '/tmp',
    path    => '/bin:/usr/bin',
    creates => "/tmp/${package_filename}",
  }

  package { 'puppet-release':
    name     => $package_name,
    provider => $package_provider,
    source   => "/tmp/${package_filename}",
    require  => Exec['puppet-release'],
  }
}
