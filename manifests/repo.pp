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
#   [String] The name of the `puppet-release` package to be installed, defaulting
#   to `${platform_name}-release` from `puppet::globals`.
#
# @param decommission_packages [Array[String]] List of old or deprecated Puppet
#   platform packages to remove before installing `puppet-release`. Defaults
#   to `puppet::globals::decommission_packages`.
#
# @param package_filename [String] The filename for the downloaded `puppet-release`
#   package, derived from `puppet::globals::package_filename`.
#
# @param platform_repository [String] The URL for the platform-specific Puppet
#   repository, constructed from `puppet::globals::platform_repository`.
#
# @param package_provider [String] The package provider to use for installing
#   `puppet-release`, typically `rpm` or `dpkg` based on the operating system
#  family, as set in `puppet::params`.
#
class puppet::repo (
  String  $package_name = $puppet::globals::package_name,
  Array[String] $decommission_packages = $puppet::globals::decommission_packages,
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

    $decommission_packages.each |String $puppet_release| {
      package { $puppet_release:
        ensure => absent,
        before => Package['puppet-release'],
      }
    }
  }
}
