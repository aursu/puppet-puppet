# @summary Puppet server installation
#
# Puppet single host installation (Puppet Agent/Server/PuppetDB)
#
# @example
#   include puppet::profile::server
#
# @param sameca
# @param platform_name
# @param server
# @param server_ipaddress
#
# @param use_puppetdb
#   Boolean. Default is true. If set puppet.conf will be set to use PuppetDB for
#   storeconfigs and reports storage. Also PuppetDB will be managed through
#   puppetlabs-puppetdb module (including PostgreSQL database)
#
# @param puppetdb_local
#   This parameter controls whether PuppetDB should be installed on the same
#   server as the Puppet Server. Setting this parameter to true enables a local
#   installation of PuppetDB alongside the Puppet Server, facilitating a
#   compact setup where both services run on a single machine.
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
# @param puppetdb_ssl_protocols
# @param puppetdb_cipher_suites
#
# @param manage_puppet_config
#   Boolean. Default is false. If set then class Puppetdb::Master::Config will
#   check puppet.conf (using Ini_setting resources) for proper setup of report/reports
#   and storeconfigs/storeconfigs_backend directives. By default class Puppet
#   generates Puppet config from template therefore we do not manage it inside
#   class Puppetdb::Master::Config.
#
# @param postgres_local
#
# @param manage_database
#   Boolean. Default is true. If set then class Puppetdb will use puppetlabs/postgresql
#   for Postgres database server management and PuppetDB database setup
#
# @param postgres_database_host
# @param postgres_database_name
# @param postgres_database_username
# @param postgres_database_password
#
# @param manage_puppetdb_firewall
#   Boolean. Default is false. If set than class Puppetdb::Server will use
#   puppetlabs/firewall for firewall rules setup, iptables/ip6tables services
#   management
#
# @param r10k_cachedir
# @param hosts_update
# @param import_path
# @param use_common_env
# @param common_envname
# @param ca_server
#
# @param enc_envname
#   The name of ENC environment inside Puppet environments path.
#   Use it to override default value 'enc'
#
# @param r10k_crontab_setup
#   Whether to setup crontab job to sync Puppet code
#
# @param manage_webserver_conf
#   Whether to manage webserver.conf or not
#
class puppet::profile::server (
  Boolean $sameca = true,
  Puppet::Platform $platform_name = 'puppet8',
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
  Boolean $hosts_update = true,
  Stdlib::Unixpath $import_path = '/root/ca',
  Boolean $use_common_env = false,
  Optional[String] $common_envname = undef,
  Optional[Stdlib::Host] $ca_server = undef,
  Optional[String] $enc_envname  = undef,
  Boolean $r10k_crontab_setup = false,
  Boolean $manage_webserver_conf = false,
  Boolean $manage_fileserver_config = true,
  Hash[String, Stdlib::Absolutepath] $mount_points = {},
  Optional[String] $certname = undef,
  Boolean $manage_repo = true,
  Optional[Stdlib::Unixpath] $r10k_cachedir = undef,
) {
  $static_certname = $certname ? {
    String  => true,
    default => false,
  }

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
    manage_repo      => $manage_repo,
  }

  if $use_puppetdb and $puppetdb_local {
    class { 'puppetdb::globals':
      version => $puppet::puppetdb_version,
    }
  }

  class { 'puppet::globals':
    platform_name => $platform_name,
    r10k_cachedir => $r10k_cachedir,
  }

  class { 'puppet::agent':
    hosts_update  => $hosts_update,
    manage_config => false,
  }

  class { 'puppet::server::install': }

  class { 'puppet::config':
    server_mode              => true,
    ca_server                => $ca_server,
    manage_webserver_conf    => $manage_webserver_conf,
    manage_fileserver_config => $manage_fileserver_config,
    mount_points             => $mount_points,
    static_certname          => $static_certname,
    certname                 => $certname,
  }

  # r10k is not optional in our workflow, it should replace initial setup with
  # real infrastructure setup.
  class { 'puppet::r10k::install':
    manage_puppet_config => $manage_puppet_config,
    r10k_cachedir        => $r10k_cachedir,
  }

  class { 'puppet::r10k::config':
    r10k_config_setup => false,
    cachedir          => $r10k_cachedir,
  }

  class { 'puppet::server::setup':
    r10k_config_manage => true,
    r10k_crontab_setup => $r10k_crontab_setup,
  }
  contain puppet::server::setup

  Class['puppet::r10k::install'] -> Class['puppet::server::setup']

  # https://puppet.com/docs/puppetdb/latest/install_via_module.html#step-2-assign-classes-to-nodes
  # 1) If you are installing PuppetDB on the same server as your Puppet Server, assign
  #    the `puppetdb` and `puppetdb::master::config` classes to it.
  # 2) If you want to run PuppetDB on its own server with a local PostgreSQL
  #    instance, assign the puppetdb class to it, and assign the puppetdb::master::config
  #    class to your Puppet Server. Make sure to set the class parameters as necessary.
  if $use_puppetdb {
    include puppet::params

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
      terminus_package               => $puppet::params::puppetdb_terminus_package,
    }

    Class['puppetdb::master::config'] -> Class['puppet::service']
  }

  class { 'puppet::service': }

  Class['puppet::agent'] -> Class['puppet::config']
}
