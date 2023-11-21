# @summary r10k run
#
# Single r10k run
#
# @example
#   include puppet::r10k::run
class puppet::r10k::run (
  Stdlib::Absolutepath $r10k_path = $puppet::params::r10k_path,
  Boolean $setup_on_each_run = $puppet::environment_setup_on_each_run,
  Integer $environment_setup_timeout = 900,
  Optional[Stdlib::Absolutepath] $cwd = undef,
) inherits puppet::params {
  include puppet::r10k::install

  exec { 'environment-setup':
    command     => "${r10k_path} deploy environment -p",
    cwd         => $cwd,
    refreshonly => !$setup_on_each_run,
    path        => '/bin:/usr/bin',
    timeout     => $environment_setup_timeout,
  }

  Class['puppet::r10k::install'] -> Exec['environment-setup']
}
