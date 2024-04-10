# @summary PuppetDB server
#
# PuppetDB server on separate host
#
# https://puppet.com/docs/puppetdb/latest/install_via_module.html#step-2-assign-classes-to-nodes
# 1) If you are installing PuppetDB on the same server as your Puppet Server, assign
#    the `puppetdb` and `puppetdb::master::config` classes to it.
# 2) If you want to run PuppetDB on its own server with a local PostgreSQL
#    instance, assign the puppetdb class to it, and assign the puppetdb::master::config
#    class to your Puppet Server. Make sure to set the class parameters as necessary.
#
# @example
#   include puppet::puppetdb
#
# @param manage_database
#   Boolean. Default is true. If set then class Puppetdb will use puppetlabs/postgresql
#   for Postgres database server management and PuppetDB database setup
#
# @param manage_firewall
#   Boolean. Default is false. If set than class Puppetdb::Server will use
#   puppetlabs/firewall for firewall rules setup, iptables/ip6tables services
#   management
#
# @param manage_cron
#   Specifies whether to manage crontab entries. This setting is critical for
#   containerized environments where crontab may not be available.
#
class puppet::puppetdb (
  Boolean $manage_database = true,
  Stdlib::Host $postgres_database_host = 'localhost',
  String $postgres_database_name = 'puppetdb',
  String $postgres_database_username = 'puppetdb',
  String $postgres_database_password = 'puppetdb',
  Array[String] $ssl_protocols = ['TLSv1.2', 'TLSv1.3'],
  Array[String] $cipher_suites = [
    'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
    'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
    'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
    'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256',
  ],
  Boolean $manage_firewall = false,
  Boolean $manage_cron = true,
) {
  if $manage_database {
    include lsys_postgresql

    postgresql::server::extension { "${postgres_database_name}-pg_trgm":
      extension => 'pg_trgm',
      database  => $postgres_database_name,
    }

    Class['postgresql::server'] -> Class['puppetdb']
    Postgresql::Server::Extension["${postgres_database_name}-pg_trgm"] -> Class['puppetdb']
  }

  if $manage_cron {
    include puppetdb::params
    $automatic_dlo_cleanup = $puppetdb::params::automatic_dlo_cleanup
  }
  else {
    $automatic_dlo_cleanup = false
  }

  class { 'puppetdb':
    database              => 'postgres',
    manage_dbserver       => false,
    database_host         => $postgres_database_host,
    database_name         => $postgres_database_name,
    database_username     => $postgres_database_username,
    database_password     => $postgres_database_password,
    manage_firewall       => $manage_firewall,

    manage_database       => $manage_database,

    ssl_protocols         => join($ssl_protocols, ','),
    cipher_suites         => join($cipher_suites, ','),

    automatic_dlo_cleanup => $automatic_dlo_cleanup,
  }

  contain puppetdb
}
