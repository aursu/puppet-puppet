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
#   server. As ::fqdn could be ot resolvable it is possible to set up server name
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
#   Boolean. Default is true. If set then class Puppetdb will use puppetlabs/postgresql
#   for Postgres database server management and PuppetDB database setup
#
# @param manage_puppetdb_firewall
#   Boolean. Default is false. If set than class Puppetdb::Server will use
#   puppetlabs/firewall for firewall rules setup, iptables/ip6tables services
#   management
#
class puppet::profile::server (
    Boolean $sameca                     = true,
    Puppet::Platform
            $platform_name              = 'puppet7',
    String  $server                     = 'puppet',
    Optional[String]
            $server_ipaddress           = '127.0.0.1',
    Boolean $use_puppetdb               = true,
    Boolean $puppetdb_local             = true,
    String  $puppetdb_server            = 'puppet',
    Array[String]
            $puppetdb_ssl_protocols     = ['TLSv1.2'],
    Array[String]
            $puppetdb_cipher_suites     = [
                                            'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
                                            'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
                                            'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
                                            'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
                                            'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
                                            'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'
                                          ],
    Boolean $manage_puppet_config       = false,
    Boolean $postgres_local             = true,
    String  $postgres_database_name     = 'puppetdb',
    String  $postgres_database_username = 'puppetdb',
    String  $postgres_database_password = 'puppetdb',
    Boolean $manage_puppetdb_firewall   = false,
    Stdlib::Unixpath
            $r10k_cachedir              = $puppet::params::r10k_cachedir,
    Boolean $hosts_update               = true,
    Stdlib::Unixpath
            $import_path                = '/root/ca',
) inherits puppet::params
{
    # https://tickets.puppetlabs.com/browse/SERVER-346
    class { 'puppet':
      server           => $server,
      server_ipaddress => $server_ipaddress,
      use_puppetdb     => $use_puppetdb,
      sameca           => $sameca,
    }

    class { 'puppet::globals':
      platform_name => $platform_name,
    }

    class { 'puppet::agent::install': }
    class { 'puppet::server::install': }
    class { 'puppet::config': }

    if $sameca {
      class { 'puppet::server::ca::import':
        import_path => $import_path,
      }

      Class['puppet::server::ca::import'] -> Class['puppetdb']
      Class['puppet::server::ca::import'] -> Class['puppet::service']
    }

    # r10k is not optional in our workflow, it should replace initial setup with
    # real infrastructure setup.
    class { 'puppet::r10k::gem_install':
      manage_puppet_config => $manage_puppet_config,
      r10k_cachedir        => $r10k_cachedir,
    }

    class { 'puppet::server::setup':
        r10k_config_setup => false,
        cachedir          => $r10k_cachedir,
    }

    Class['puppet::r10k::gem_install'] -> Class['puppet::server::setup']

    # https://puppet.com/docs/puppetdb/latest/install_via_module.html#step-2-assign-classes-to-nodes
    if $puppetdb_local {
        if $postgres_local {
          include lsys::postgres

          postgresql::server::extension { "${postgres_database_name}-pg_trgm":
              extension => 'pg_trgm',
              database  => $postgres_database_name,
          }

          Class['postgresql::server'] -> Class['puppetdb']
          Postgresql::Server::Extension["${postgres_database_name}-pg_trgm"] -> Class['puppetdb']
        }

        class { 'puppetdb':
          database          => 'postgres',
          manage_dbserver   => false,
          database_name     => $postgres_database_name,
          database_username => $postgres_database_username,
          database_password => $postgres_database_password,
          manage_firewall   => $manage_puppetdb_firewall,
          ssl_protocols     => join($puppetdb_ssl_protocols, ','),
          cipher_suites     => join($puppetdb_cipher_suites, ','),
        }

        # Notes:
        # 1) as 'puppet' hostname by default is set by class Puppet - use it as
        # PuppetDB server name (predefined in profile parameters as
        # puppetdb_server)
        # 2) By default class Puppet generates Puppet config (puppet.conf) from
        # template therefore we do not want to manage it inside class
        # Puppetdb::Master::Config (see 'manage_puppet_config' parameter
        # description)
        # 3) Puppet service resource name provided by Puppet::Service class has
        # alias 'puppet-server'
        #
        class { 'puppetdb::master::config':
          puppetdb_server                => $puppetdb_server,
          manage_storeconfigs            => $manage_puppet_config,
          manage_report_processor        => $manage_puppet_config,
          create_puppet_service_resource => false,
          puppet_service_name            => 'puppet-server',
        }

        Class['puppetdb'] -> Class['puppet::service']
        Class['puppetdb::master::config'] -> Class['puppet::service']
    }

    class { 'puppet::service': }
    class { 'puppet::setup':
      hosts_update => $hosts_update,
    }

    Class['puppet::server::ca::import'] -> Class['puppet::service']
    Class['puppet::server::ca::import'] -> Class['puppetdb']
}
