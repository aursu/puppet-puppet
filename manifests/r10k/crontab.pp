# @summary r10k crontab
#
# r10k crontab setup
#
# @param r10k_path
# @param decomission
#   Enable decommission mode for r10k crontab entry.
#
# @example
#   include puppet::r10k::crontab
class puppet::r10k::crontab (
  Stdlib::Absolutepath $r10k_path = $puppet::globals::r10k_path,
  Boolean $decomission = false,
) inherits puppet::globals {
  include puppet::r10k::install
  include puppet::r10k::config

  $cron_ensure = $decomission ? {
    true    => 'absent',
    default => 'present',
  }

  cron { 'r10k-crontab':
    ensure  => $cron_ensure,
    command => "/usr/bin/flock -n /run/r10k.lock ${r10k_path} deploy environment -p",
    user    => 'root',
    minute  => '*',
  }

  Class['puppet::r10k::install'] -> Cron['r10k-crontab']
  Class['puppet::r10k::config'] -> Cron['r10k-crontab']
}
