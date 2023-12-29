# @summary Puppet server bootstrap
#
# Puppet server bootstrap
# This is intended to be run via `puppet apply` command
#
# @example
#   include puppet::server::bootstrap
class puppet::server::bootstrap (
  Puppet::Platform $platform_name = 'puppet7',
) {
  class { 'puppet::globals':
    platform_name => $platform_name,
  }

  class { 'puppet::setup':
    server_name      => 'puppet',
    server_ipaddress => '127.0.0.1',
  }

  class { 'puppet::agent::install':
    agent_version => 'latest',
  }

  include puppet::r10k::install
  include puppet::server::bootstrap::globals
  include puppet::server::bootstrap::ssh

  $access_data = $puppet::server::bootstrap::globals::access_data

  if $access_data[0] {
    class { 'puppet::r10k::run':
      setup_on_each_run => true,
    }
  }

  class { 'puppet::server::ca::import':
    import_path => '/root/ca',
  }

  class { 'puppet::service':
    server_service_ensure => 'running',
    server_service_enable => true,
  }

  Class['puppet::server::ca::import'] -> Class['puppet::service']
}
