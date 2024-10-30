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

  $tmpdir = $puppet::globals::tmpdir
  $package_source = $puppet::globals::package_source
  $package_check = $puppet::globals::package_check

  if $manage_repo {
    # use own tmp directory to not interferre with puppet_agent module
    file { $tmpdir:
      ensure => directory,
    }

    exec { 'puppet-release':
      command => "curl ${platform_repository} -f -s -o ${package_source}",
      cwd     => $tmpdir,
      path    => '/bin:/usr/bin',
      creates => $package_source,
      unless  => $package_check,
      require => File[$tmpdir],
    }

    package { 'puppet-release':
      name     => $package_name,
      provider => $package_provider,
      source   => $package_source,
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
