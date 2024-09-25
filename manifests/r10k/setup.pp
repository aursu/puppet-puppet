# @summary Setup r10k
#
# Setup r10k install and configure
#
# @example
#   include puppet::r10k::setup
class puppet::r10k::setup inherits puppet::params {
  include puppet::agent::install

  $r10k_config_file = $puppet::params::r10k_config_file
  $r10k_config_path = dirname($r10k_config_file)

  # /opt/puppetlabs/puppet/cache/r10k
  $r10k_vardir = $puppet::params::r10k_vardir

  exec { 'r10k-vardir':
    command => "mkdir -p ${r10k_vardir}",
    creates => $r10k_vardir,
    path    => '/bin:/usr/bin',
  }

  # exec in order to avoid conflict with r10k module
  exec { 'r10k-confpath-setup':
    command => "mkdir -p ${r10k_config_path}",
    creates => $r10k_config_path,
    path    => '/bin:/usr/bin',
  }

  Class['puppet::agent::install'] -> Exec['r10k-vardir']
  Class['puppet::agent::install'] -> Exec['r10k-confpath-setup']
}
