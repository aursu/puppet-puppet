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
# @param manage_source
#   Debian only. Whether the active platform's apt source is declared as an
#   `apt::source` rather than left to the release package that shipped it.
#
#   ⚠ **Installing the release package is not enough, and the gap is invisible.**
#   The package owns `/etc/apt/sources.list.d/<platform>-release.list`, so
#   `Package['puppet-release']` being installed is the only thing Puppet checks.
#   Once installed it is never revisited, and anything that happens to the file
#   afterwards is a state Puppet cannot observe. Two ways that bites, both
#   measured on this estate after `do-release-upgrade`:
#
#   * The file is **renamed to `.list.distUpgrade`** and no live source remains.
#     The host silently stops receiving agent updates while `apt update` still
#     exits 0.
#   * The file **survives but names the old release** - `ubuntu22.04` on a host
#     now running noble - so the host pulls packages built for the previous OS.
#
#   Declaring it through `apt::source` fixes both with one resource, because the
#   suite comes from the OS fact on every run: a missing file is recreated and a
#   stale one is rewritten. The release package is still installed and still
#   provides the keyring and the pin - what changes is that the *source* is now
#   a resource Puppet owns rather than a side effect it infers.
#
# @param source_keyring
#   Keyring the source references with `signed-by=`. `undef` on Puppet Inc
#   platforms, whose key lives in `trusted.gpg.d` and needs no reference.
#
class puppet::repo (
  String  $package_name = $puppet::globals::repo_name,
  Array[String] $decommission_packages = $puppet::globals::decommission_packages,
  String $package_filename = $puppet::globals::repo_filename,
  String $platform_repository = $puppet::globals::platform_repository,
  String $package_provider = $puppet::params::package_provider,
  Boolean $manage_source = true,
  Optional[Stdlib::Absolutepath] $source_keyring = $puppet::globals::repo_keyring,
) inherits puppet::globals {
  include puppet
  $manage_repo = $puppet::manage_repo

  $tmpdir = $puppet::globals::tmpdir
  $package_source = $puppet::globals::repo_source
  $package_check = $puppet::globals::repo_check

  # Qualified rather than relied on through inheritance: the same three values
  # the release package's own filename is built from, so the source and the
  # package can never disagree about which release this host is.
  $source_location = $puppet::globals::repo_urlbase
  $source_release  = $puppet::globals::version_codename
  $source_repos    = $puppet::globals::platform_name

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

    # The active platform's source, owned rather than inferred. See @param
    # manage_source: the release package installs this file once and Puppet then
    # has no way to notice it being renamed away or left naming the previous
    # release. apt::source writes it from the OS fact on every run, so both
    # failure modes converge on their own.
    #
    # notify_update is off because this class already owns its refresh below -
    # leaving it on would queue a second apt-get update through
    # Class['apt::update'] for the same change.
    if $manage_source and $facts['os']['family'] == 'Debian' {
      apt::source { $package_name:
        location      => $source_location,
        release       => $source_release,
        repos         => $source_repos,
        keyring       => $source_keyring,
        include       => { 'deb' => true, 'src' => false },
        notify_update => false,
        require       => Package['puppet-release'],
      }

      # The same do-release-upgrade leftovers the decommission loop removes for
      # retired platforms, for the platform actually in use. `.list` is excluded
      # deliberately - that is the file apt::source writes.
      ['sources', 'list.distUpgrade', 'list.save'].each |String $ext| {
        file { "/etc/apt/sources.list.d/${package_name}.${ext}":
          ensure => absent,
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

      # A rewritten or recreated source needs the same refresh the package does,
      # and on the hosts this fixes the package will NOT change - it is already
      # installed, which is the whole reason the source went unnoticed.
      if $manage_source {
        Apt::Source[$package_name] ~> Exec['puppet-release-apt-update']
      }
    }
  }
}
