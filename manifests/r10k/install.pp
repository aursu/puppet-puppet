# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::r10k::install
#
# @param manage_puppet_config
# @param r10k_cachedir
#
class puppet::r10k::install (
  Boolean $manage_puppet_config = false,
  Stdlib::Absolutepath $r10k_cachedir = $puppet::globals::r10k_cachedir,
) inherits puppet::globals {
  include puppet::agent::install
  include puppet::r10k::dependencies
  include puppet::r10k::setup

  class { 'r10k':
    provider          => $puppet::params::r10k_package_provider,
    manage_modulepath => $manage_puppet_config,
    cachedir          => $r10k_cachedir,
  }

  Class['puppet::r10k::setup'] -> Class['r10k']
  Class['puppet::agent::install'] -> Class['r10k']
  Class['puppet::r10k::dependencies'] -> Class['r10k']
}
