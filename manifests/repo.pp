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
#   On Debian, removing the package is not enough to decommission the
#   repository: `ensure => absent` leaves the package in state `rc` with its apt
#   source still on disk and still read by apt. The apt sources are therefore
#   removed explicitly - including the disabled `.sources` and
#   `.list.distUpgrade` that `do-release-upgrade` leaves behind, which no
#   package owns, and the version-specific `puppet<N>-keyring.gpg`.
#
#   The OpenVox keyring is shared between openvox7 and openvox8, as are the
#   `*-release.pref` files, so those are deliberately kept.
#
# @param package_filename [String] The filename for the downloaded `puppet-release`
#   package, derived from `puppet::globals::repo_filename`.
#
# @param platform_repository [String] The URL for the platform-specific Puppet
#   repository, constructed from `puppet::globals::platform_repository`.
#
# @param package_provider [String] The package provider to use for installing
#   `puppet-release`, typically `rpm` or `dpkg` based on the operating system
#  family, as set in `puppet::params`.
#
class puppet::repo (
  String  $package_name = $puppet::globals::repo_name,
  Array[String] $decommission_packages = $puppet::globals::decommission_packages,
  String $package_filename = $puppet::globals::repo_filename,
  String $platform_repository = $puppet::globals::platform_repository,
  String $package_provider = $puppet::params::package_provider,
) inherits puppet::globals {
  include puppet
  $manage_repo = $puppet::manage_repo

  $tmpdir = $puppet::globals::tmpdir
  $package_source = $puppet::globals::repo_source
  $package_check = $puppet::globals::repo_check

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

    # ⚠ `ensure => purged` looks like the obvious answer here and is the wrong
    # one. Measured on Ubuntu 22.04: purging works, but the apt provider then
    # runs `apt-mark manual <package>` against a package whose repository has
    # just been removed, which exits 100 and fails the resource - taking every
    # resource ordered after it down with it, including the file removals below.
    # The purge itself had already succeeded, so the run reported a failure for
    # work it had actually done, and only the next run came back clean.
    #
    # `absent` leaves the conffiles, which is the original problem, so the file
    # removals below do that job explicitly instead. They are what decommissions
    # the repository; the package state alone never did.
    $decommission_packages.each |String $puppet_release| {
      package { $puppet_release:
        ensure => absent,
        before => Package['puppet-release'],
      }

      if $facts['os']['family'] == 'Debian' {
        $release_data = split($puppet_release, '[-]')
        $platform     = $release_data[0]

        # These are the files that actually retire the repository. `.list` is
        # the package's own conffile, which survives removal; the rest are not
        # owned by any package at all - do-release-upgrade rewrites third-party
        # sources as it goes and leaves a disabled `.sources` (deb822), a
        # `.list.distUpgrade` and sometimes a `.list.save` behind.
        #
        # Those leftovers matter more than they look: because the release
        # package is still installed and still satisfies its own resource,
        # nothing here would otherwise notice that the repository had been
        # switched off. Seen on a host upgraded jammy -> noble, where the Puppet
        # repository had been silently disabled and the agent had quietly
        # stopped receiving updates.
        ['list', 'sources', 'list.distUpgrade', 'list.save'].each |String $ext| {
          file { "/etc/apt/sources.list.d/${puppet_release}.${ext}":
            ensure  => absent,
            require => Package[$puppet_release],
            before  => Package['puppet-release'],
          }
        }

        # The Puppet keyring is version-specific - puppet7-keyring.gpg,
        # puppet8-keyring.gpg - so it belongs to exactly one release package and
        # goes with it.
        #
        # ⚠ The OpenVox keyring is NOT version-specific: openvox7-release and
        # openvox8-release both ship /etc/apt/keyrings/openvox-keyring.gpg.
        # Removing it while decommissioning openvox7 in favour of openvox8 would
        # delete the key the new repository needs. So it is deliberately left
        # alone, and the same applies to the shared *-release.pref files.
        if $platform in ['puppet5', 'puppet6', 'puppet7', 'puppet8'] {
          file { "/etc/apt/trusted.gpg.d/${platform}-keyring.gpg":
            ensure  => absent,
            require => Package[$puppet_release],
            before  => Package['puppet-release'],
          }
        }
      }
    }

    # Installing the release package only adds the source; the package index for
    # it does not exist until apt is refreshed. Without this the very next
    # resource - the agent package, ordered after this class - fails with
    # "E: Unable to locate package openvox-agent" on the same run, and only
    # recovers if something else happens to refresh apt before the next one.
    if $facts['os']['family'] == 'Debian' {
      exec { 'puppet-release-apt-update':
        command     => 'apt-get update',
        path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
        refreshonly => true,
        subscribe   => Package['puppet-release'],
      }
    }
  }
}
