# puppet::server::setup
#
# This class setup dynamic environments using r10k invocation. If r10k is not
# configured, than it will setup it from template
#
# @summary Puppet server environment setup
#
# @example
#   include puppet::server::setup
class puppet::server::setup (
  Boolean $r10k_config_manage = true,
  Boolean $r10k_crontab_setup = $puppet::r10k_crontab_setup,
) inherits puppet::params {
  include puppet::r10k::install
  include puppet::r10k::setup
  include puppet::server::keys

  class { 'puppet::r10k::run':
    cwd => '/',
  }

  if $r10k_config_manage {
    include puppet::r10k::config

    # no sense to have crontab without r10k configuration
    if $r10k_crontab_setup {
      include puppet::r10k::crontab
    }

    Class['puppet::r10k::config'] ~> Class['puppet::r10k::run']
  }
}
