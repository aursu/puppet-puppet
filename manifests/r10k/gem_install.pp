# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::r10k::gem_install
#
# @param manage_puppet_config
# @param r10k_cachedir
#
class puppet::r10k::gem_install (
  Boolean $manage_puppet_config = false,
  Stdlib::Absolutepath $r10k_cachedir = $puppet::params::r10k_cachedir,
) inherits puppet::params {
  include puppet::agent::install

  # Puppet 6 comes with Ruby >= 2.5
  if versioncmp($facts['puppetversion'], '6.0.0') >= 0 {
    $cri_ensure = 'installed'
  }
  else {
    # cri-2.15.10 requires Ruby ~> 2.3
    $cri_ensure = '2.15.10'
  }

  package { 'cri':
    ensure   => $cri_ensure,
    provider => 'puppet_gem',
  }

  class { 'r10k':
    provider          => 'puppet_gem',
    manage_modulepath => $manage_puppet_config,
    cachedir          => $r10k_cachedir,
  }

  Class['puppet::agent::install'] -> Class['r10k']
  Package['cri'] -> Class['r10k']
}
