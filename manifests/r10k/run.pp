# @summary r10k run
#
# Single r10k run
#
# @param setup_on_each_run
#   Controls whether the r10k command is executed on every Puppet agent run on the Puppet server
#   or only triggered by a notify event from other resources in the Puppet catalog.
#
# @param cwd
#   The directory from which the r10k command is executed. It may include the r10k.yaml
#   configuration file.
#
# @param user
#
# @example
#   include puppet::r10k::run
class puppet::r10k::run (
  Stdlib::Absolutepath $r10k_path = $puppet::params::r10k_path,
  Boolean $setup_on_each_run = $puppet::environment_setup_on_each_run,
  Integer $environment_setup_timeout = 900,
  Optional[Stdlib::Absolutepath] $cwd = undef,
  Optional[Enum['root', 'puppet']] $user = undef,
) inherits puppet::params {
  include puppet::r10k::install

  $r10k_lock = $user ? {
    'puppet' => '/run/puppet.r10k.lock',
    default  => '/run/r10k.lock',
  }

  exec { 'environment-setup':
    command     => "/usr/bin/flock -n ${r10k_lock} ${r10k_path} deploy environment -p",
    cwd         => $cwd,
    user        => $user,
    refreshonly => !$setup_on_each_run,
    path        => '/bin:/usr/bin',
    timeout     => $environment_setup_timeout,
  }

  Class['puppet::r10k::install'] -> Exec['environment-setup']
}
