# @summary Setup r10k
#
# Setup r10k install and configure
#
# @example
#   include puppet::r10k::setup
class puppet::r10k::setup inherits puppet::params {
  include puppet::agent::install
  include puppet::server::setup::filesystem

  $r10k_config_file = $puppet::params::r10k_config_file
  $r10k_config_path = dirname($r10k_config_file)

  # /opt/puppetlabs/puppet/cache/r10k
  $r10k_vardir = $puppet::params::r10k_vardir

  exec { 'r10k-vardir':
    command => "mkdir -p ${r10k_vardir}",
    creates => $r10k_vardir,
    path    => '/bin:/usr/bin',
  }

  # Use exec to avoid conflict with the r10k module, which manages the resource File['/etc/puppetlabs/r10k']
  # This ensures we don't interfere with the r10k module's file resource.
  exec { 'r10k-confpath-setup':
    command => "mkdir -p ${r10k_config_path}",
    creates => $r10k_config_path,
    path    => '/bin:/usr/bin',
  }

  file { $r10k_vardir:
    ensure  => directory,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0750',
    require => Exec['r10k-vardir'],
  }

  Class['puppet::agent::install'] -> Exec['r10k-vardir']
  Class['puppet::agent::install'] -> Exec['r10k-confpath-setup']
}
