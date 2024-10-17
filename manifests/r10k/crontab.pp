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
) inherits puppet::params {
  include puppet::r10k::install
  include puppet::r10k::config

  cron { 'r10k-crontab':
    command => "/usr/bin/flock -n /run/r10k.lock ${r10k_path} deploy environment -p",
    user    => 'root',
    minute  => '*',
  }

  Class['puppet::r10k::install'] -> Cron['r10k-crontab']
  Class['puppet::r10k::config'] -> Cron['r10k-crontab']
}
