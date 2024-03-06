# @summary Puppet server bootstrap
#
# Puppet server bootstrap
# This is intended to be run via `puppet apply` command
#
# @param path
#   The directory path on the Puppet server designated for searching assets such as eYAML keys,
#   Hiera configuration, and r10k configuration files. This directory is crucial for the proper
#   setup and operation of Puppet, as it stores essential configuration files and keys. Specifically,
#   the path may include the following files:
#     - keys/public_key.pkcs7.pem: The public key for eYAML encryption.
#     - keys/private_key.pkcs7.pem: The private key for eYAML decryption.
#     - hiera.yaml: The main Hiera configuration file.
#     - data/secrets.eyaml: Encrypted data file for sensitive information.
#     - gitservers.txt: List of Git servers for module repositories.
#     - r10k.yaml: Configuration file for managing module deployments with r10k.
#     - ca/ca_key.pem
#     - ca/ca_crt.pem
#     - ca/ca_crl.pem
#
# @param agent_version
#   Version of Puppet agent to install on the Puppet server
#
# @param node_environment
#   Puppet environment to assign to Puppet server node
#
# @param use_ssh
#   Specifies if SSH is required for authentication or authorization to access 
#   Puppet repositories on Git.
#
# @example
#   include puppet::server::bootstrap
class puppet::server::bootstrap (
  Puppet::Platform $platform_name = 'puppet8',
  Optional[Stdlib::Unixpath] $path = undef,
  String $agent_version = 'latest',
  Optional[String] $node_environment = undef,
  Boolean $use_ssh = true,
) {
  class { 'puppet::globals':
    platform_name => $platform_name,
  }

  class { 'puppet::agent::install':
    agent_version => $agent_version,
  }

  class { 'puppet::config':
    node_environment => $node_environment,
    # to avoid "Server Error: Could not find terminus puppetdb for indirection facts"
    # as PuppetDB is not installed yet
    use_puppetdb     => false,
  }

  class { 'puppet::setup':
    server_name      => 'puppet',
    server_ipaddress => '127.0.0.1',
  }

  include puppet::r10k::install
  include puppet::server::bootstrap::globals
  include puppet::server::bootstrap::setup
  include puppet::server::bootstrap::keys
  include puppet::server::bootstrap::hiera
  include puppet::server::bootstrap::ssh

  $access_data = $puppet::server::bootstrap::globals::access_data
  $bootstrap_path = $puppet::server::bootstrap::globals::bootstrap_path
  $cwd = $puppet::server::bootstrap::globals::cwd

  if ($use_ssh and $access_data[0]) or ! $use_ssh {
    class { 'puppet::r10k::run':
      setup_on_each_run => true,
      cwd               => $cwd,
      require           => Class['puppet::server::bootstrap::ssh'],
    }
  }

  class { 'puppet::server::ca::import':
    import_path => "${bootstrap_path}/ca",
    require     => File["${bootstrap_path}/ca"],
  }

  class { 'puppet::service':
    server_service_ensure => 'running',
    server_service_enable => true,
  }

  Class['puppet::server::ca::import'] -> Class['puppet::service']
}
