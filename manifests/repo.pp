# puppet::repo
#
# Setup Puppet Platform repository
#
# @summary Setup Puppet Platform repository
#
# @example
#   include puppet::repo
#
# @param package_name
# @param deccomission_packages
# @param package_filename
# @param platform_repository
# @param package_provider
# @param
#
class puppet::repo (
  String  $package_name = $puppet::globals::package_name,
  Array[String] $deccomission_packages = $puppet::globals::deccomission_packages,
  String $package_filename = $puppet::globals::package_filename,
  String $platform_repository = $puppet::globals::platform_repository,
  String $package_provider = $puppet::params::package_provider,
) inherits puppet::globals {
  $manage_repo = $puppet::manage_repo
  if $manage_repo {
    exec { 'puppet-release':
      command => "curl ${platform_repository} -s -o ${package_filename}",
      cwd     => '/tmp',
      path    => '/bin:/usr/bin',
      creates => "/tmp/${package_filename}",
      unless  => "rpm --quiet -qip ${package_filename}",
    }

    package { 'puppet-release':
      name     => $package_name,
      provider => $package_provider,
      source   => "/tmp/${package_filename}",
      require  => Exec['puppet-release'],
    }

    $deccomission_packages.each |String $puppet_release| {
      package { $puppet_release:
        ensure => absent,
        before => Package['puppet-release'],
      }
    }
  }
}
