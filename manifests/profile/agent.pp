# @summary Puppet agent installation and configuration
#
# This class installs and configures Puppet agent
#
# @param platform_name
#   Puppet platform name. Supported values: puppet7, puppet8, openvox7, openvox8
#
# @param server
#   Puppet server hostname
#
# @param hosts_update
#   Whether to update /etc/hosts file with puppet server entry
#
# @param ca_server
#   Puppet CA server hostname (if different from main server)
#
# @param certname
#   Certificate name for this agent. If not specified, uses FQDN
#
# @param manage_repo
#   Whether to manage Puppet platform repository
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
  class { 'puppet::globals':
    platform_name => $platform_name,
  }

  class { 'puppet':
    server      => $server,
    ca_server   => $ca_server,
    manage_repo => $manage_repo,
  }

  class { 'puppet::agent':
    certname      => $certname,
    server        => $server,
    ca_server     => $ca_server,
    hosts_update  => $hosts_update,
    manage_config => true,
  }
}
