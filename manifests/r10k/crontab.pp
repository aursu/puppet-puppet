# @summary r10k crontab
#
# r10k crontab setup
#
# @param r10k_path
# @param user
#
# @example
#   include puppet::r10k::crontab
class puppet::r10k::crontab (
  Stdlib::Absolutepath $r10k_path = $puppet::params::r10k_path,
  Optional[Enum['root', 'puppet']] $user = $puppet::env_user,
) inherits puppet::params {
  include puppet::r10k::install
  include puppet::r10k::config

  $cron_user = $user ? {
    String  => $user,
    default => 'root',
  }

  $r10k_lock = $cron_user ? {
    'puppet' => '/run/puppet.r10k.lock',
    default  => '/run/r10k.lock',
  }

  cron { 'r10k-crontab':
    command => "/usr/bin/flock -n ${r10k_lock} ${r10k_path} deploy environment -p",
    user    => $cron_user,
    minute  => '*',
  }

  Class['puppet::r10k::install'] -> Cron['r10k-crontab']
  Class['puppet::r10k::config'] -> Cron['r10k-crontab']
}
