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
  Stdlib::Absolutepath $r10k_path = $puppet::globals::r10k_path,
  Boolean $setup_on_each_run = $puppet::environment_setup_on_each_run,
  Integer $environment_setup_timeout = 900,
  Optional[Stdlib::Absolutepath] $cwd = undef,
) inherits puppet::globals {
  include puppet::r10k::install

  exec { 'environment-setup':
    command     => "/usr/bin/flock -n /run/r10k.lock ${r10k_path} deploy environment -p",
    cwd         => $cwd,
    refreshonly => !$setup_on_each_run,
    path        => '/bin:/usr/bin',
    timeout     => $environment_setup_timeout,
    umask       => '022',
  }

  Class['puppet::r10k::install'] -> Exec['environment-setup']
}
