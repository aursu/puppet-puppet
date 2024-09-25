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
  Stdlib::Absolutepath $r10k_cachedir = $puppet::globals::r10k_cachedir,
) inherits puppet::globals {
  include puppet::agent::install
  include puppet::r10k::dependencies

  class { 'r10k':
    provider          => 'puppet_gem',
    manage_modulepath => $manage_puppet_config,
    cachedir          => $r10k_cachedir,
  }

  Class['puppet::agent::install'] -> Class['r10k']
  Class['puppet::r10k::dependencies'] -> Class['r10k']
}
