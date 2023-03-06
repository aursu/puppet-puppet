# @summary Puppet server installation
#
# Puppet single host installation (Puppet Agent/Server/PuppetDB)
#
# @example
#   include puppet::profile::server
#
# @param use_puppetdb
#   Boolean. Default is true. If set puppet.conf will be set to use PuppetDB for
#   storeconfigs and reports storage. Also PuppetDB will be managed through
#   puppetlabs-puppetdb module (including PostgreSQL database)
#
# @param puppetdb_server
#   String. Default is 'puppet'. Server name for PuppetDB. Puppetdb::Master::Config
#   class (from puppetlabs-puppetdb) use ::fqdn for check connection to PuppetDB
#   server. As ::fqdn could be not resolvable it is possible to set up server name
#   via parameter puppetdb_server. Class '::puppet' by default set into /etc/hosts
#   file record
#   127.0.0.1 puppet
#   therefore hostname 'puppet' is resolvable. If you changed this behavior - you
#   should properly set parameter puppetdb_server as well
#
# @param manage_puppet_config
#   Boolean. Default is false. If set then class Puppetdb::Master::Config will
#   check puppet.conf (using Ini_setting resources) for proper setup of report/reports
#   and storeconfigs/storeconfigs_backend directives. By default class Puppet
#   generates Puppet config from template therefore we do not manage it inside
#   class Puppetdb::Master::Config.
#
# @param postgres_local
# @param manage_database
#   Boolean. Default is true. If set then class Puppetdb will use puppetlabs/postgresql
#   for Postgres database server management and PuppetDB database setup
#
# @param manage_puppetdb_firewall
#   Boolean. Default is false. If set than class Puppetdb::Server will use
#   puppetlabs/firewall for firewall rules setup, iptables/ip6tables services
#   management
#
# @param enc_envname
#   The name of ENC environment inside Puppet environments path.
#   Use it to override default value 'enc'
#
# @param r10k_crontab_setup
#   Whether to setup crontab job to sync Puppet code
#
class puppet::profile::server (
  Boolean $sameca = true,
  Puppet::Platform $platform_name = 'puppet7',
  String $server = 'puppet',
  String $server_ipaddress = '127.0.0.1',
  Boolean $use_puppetdb = true,
  Boolean $puppetdb_local = true,
  String $puppetdb_server = 'puppet',
  Array[String] $puppetdb_ssl_protocols = ['TLSv1.2', 'TLSv1.3'],
  Array[String] $puppetdb_cipher_suites = [
    'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
    'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
    'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
    'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256',
  ],
  Boolean $manage_puppet_config = false,
  Boolean $postgres_local = true,
  Boolean $manage_database = $postgres_local,
  Stdlib::Host $postgres_database_host = 'localhost',
  String $postgres_database_name = 'puppetdb',
  String $postgres_database_username = 'puppetdb',
  String $postgres_database_password = 'puppetdb',
  Boolean $manage_puppetdb_firewall = false,
  Stdlib::Unixpath $r10k_cachedir = $puppet::params::r10k_cachedir,
  Boolean $hosts_update = true,
  Stdlib::Unixpath $import_path = '/root/ca',
  Boolean $use_common_env = false,
  Optional[String] $common_envname = undef,
  Optional[Stdlib::Host] $ca_server = undef,
  Optional[String] $enc_envname  = undef,
  Boolean $r10k_crontab_setup = false,
) inherits puppet::params {
  # https://tickets.puppetlabs.com/browse/SERVER-346
  class { 'puppet':
    master           => true,
    server           => $server,
    server_ipaddress => $server_ipaddress,
    use_puppetdb     => $use_puppetdb,
    sameca           => $sameca,
    use_common_env   => $use_common_env,
    common_envname   => $common_envname,
    enc_envname      => $enc_envname,
  }

  class { 'puppet::globals':
    platform_name => $platform_name,
  }

  class { 'puppet::agent::install': }
  class { 'puppet::server::install': }

  class { 'puppet::config':
    puppet_server => true,
    ca_server     => $ca_server,
  }

  # r10k is not optional in our workflow, it should replace initial setup with
  # real infrastructure setup.
  class { 'puppet::r10k::gem_install':
    manage_puppet_config => $manage_puppet_config,
    r10k_cachedir        => $r10k_cachedir,
  }

  class { 'puppet::server::setup':
    r10k_config_setup => false,
    r10k_crontab_setup => $r10k_crontab_setup,
    cachedir          => $r10k_cachedir,
  }

  Class['puppet::r10k::gem_install'] -> Class['puppet::server::setup']

  # https://puppet.com/docs/puppetdb/latest/install_via_module.html#step-2-assign-classes-to-nodes
  # 1) If you are installing PuppetDB on the same server as your Puppet Server, assign
  #    the `puppetdb` and `puppetdb::master::config` classes to it.
  # 2) If you want to run PuppetDB on its own server with a local PostgreSQL
  #    instance, assign the puppetdb class to it, and assign the puppetdb::master::config
  #    class to your Puppet Server. Make sure to set the class parameters as necessary.
  if $use_puppetdb {
    if $puppetdb_local {
      class { 'puppet::puppetdb':
        manage_database            => $manage_database,
        postgres_database_host     => $postgres_database_host,
        postgres_database_name     => $postgres_database_name,
        postgres_database_username => $postgres_database_username,
        postgres_database_password => $postgres_database_password,
        ssl_protocols              => $puppetdb_ssl_protocols,
        cipher_suites              => $puppetdb_cipher_suites,
        manage_firewall            => $manage_puppetdb_firewall,
      }

      Class['puppet::puppetdb'] -> Class['puppet::service']
    }

    # Notes:
    # 1) as hostname by default is set by class Puppet to `puppet` - use it as
    # PuppetDB server name as well (predefined with profile parameter `puppetdb_server`)
    # 2) By default class Puppet generates Puppet config (puppet.conf) from
    # template therefore we do not want to manage it inside class
    # Puppetdb::Master::Config (see `manage_puppet_config` parameter
    # description)
    # 3) Puppet service resource name provided by Puppet::Service class has
    # name 'puppet-server'
    #
    class { 'puppetdb::master::config':
      puppetdb_server                => $puppetdb_server,
      manage_storeconfigs            => $manage_puppet_config,
      manage_report_processor        => $manage_puppet_config,
      create_puppet_service_resource => false,
      puppet_service_name            => 'puppet-server',
    }

    Class['puppetdb::master::config'] -> Class['puppet::service']
  }

  class { 'puppet::service': }
  class { 'puppet::setup':
    hosts_update => $hosts_update,
  }

  include puppet::agent::schedule

  Class['puppet::agent::install']
  -> Class['puppet::config']
  -> Class['puppet::agent::schedule']
}
