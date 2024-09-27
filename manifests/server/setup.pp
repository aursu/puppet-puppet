# puppet::server::setup
#
# This class setup dynamic environments using r10k invocation. If r10k is not
# configured, than it will setup it from template
#
# @summary Puppet server environment setup
#
# @param user
#
# @example
#   include puppet::server::setup
class puppet::server::setup (
  Boolean $r10k_config_manage = true,
  Boolean $r10k_crontab_setup = $puppet::r10k_crontab_setup,
  Optional[Enum['root', 'puppet']] $user = undef,
) inherits puppet::params {
  include puppet::r10k::install
  include puppet::r10k::setup
  include puppet::server::keys

  class { 'puppet::r10k::run':
    cwd  => '/',
    user => $user,
  }

  if $r10k_config_manage {
    include puppet::r10k::config

    # no sense to have crontab without r10k configuration
    if $r10k_crontab_setup {
      class { 'puppet::r10k::crontab':
        user => $user,
      }
    }

    Class['puppet::r10k::config'] ~> Class['puppet::r10k::run']
  }
}
