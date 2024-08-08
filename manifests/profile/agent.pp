# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::profile::agent
class puppet::profile::agent (
  Puppet::Platform $platform_name = 'puppet8',
  String $server = 'puppet',
  Boolean $hosts_update = false,
  Optional[String] $ca_server = undef,
  Optional[String] $certname = undef,
  Boolean $manage_repo = true,
) {
  class { 'puppet':
    server      => $server,
    ca_server   => $ca_server,
    manage_repo => $manage_repo,
  }

  class { 'puppet::globals':
    platform_name => $platform_name,
  }

  include puppet::agent::schedule

  class { 'puppet::agent::install': }

  class { 'puppet::agent::config':
    server           => $server,
    ca_server        => $ca_server,
    # lint:ignore:top_scope_facts
    node_environment => $::environment,
    # lint:endignore
    certname         => $certname,
  }

  class { 'puppet::setup':
    hosts_update => $hosts_update,
  }

  Class['puppet::agent::install']
  -> Class['puppet::agent::config']
  -> Class['puppet::agent::schedule']
}
