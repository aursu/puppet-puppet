# puppet::server::setup
#
# This class setup dynamic environments using r10k invocation. If r10k is not
# configured, than it will setup it from template
#
# @summary Puppet server environment setup
#
# @param r10k_config_manage
#   Whether to manage r10k configuration before environment deployment.
#
# @param r10k_crontab_setup
#   Whether to manage periodic r10k deployment cron job.
#
# @param r10k_crontab_decomission
#   Whether cron job should be decommissioned (removed) when managed.
#
# @example
#   include puppet::server::setup
class puppet::server::setup (
  Boolean $r10k_config_manage = true,
  Boolean $r10k_crontab_setup = $puppet::r10k_crontab_setup,
  Boolean $r10k_crontab_decomission = $puppet::r10k_crontab_decomission,
) inherits puppet::params {
  include puppet::r10k::install
  include puppet::r10k::setup
  include puppet::server::keys
  include puppet::server::setup::filesystem

  class { 'puppet::r10k::run':
    cwd  => '/',
  }
  contain puppet::r10k::run

  if $r10k_config_manage {
    include puppet::r10k::config

    # no sense to have crontab without r10k configuration
    if $r10k_crontab_setup {
      class { 'puppet::r10k::crontab':
        decomission => $r10k_crontab_decomission,
      }
    }

    Class['puppet::r10k::config'] ~> Class['puppet::r10k::run']
  }
}
