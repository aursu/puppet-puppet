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
# @param ssl_deploy_certs
#   This parameter will be passed into the class `puppetdb`.
#   The class `puppetdb` expects the parameters `puppetdb::ssl_key`, `puppetdb::ssl_cert`, and `puppetdb::ssl_ca_cert`
#   to be set with the appropriate SSL asset content.
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
  Boolean $ssl_deploy_certs = false,
) {
  include puppet::params

  if $manage_database {
    include lsys_postgresql

    postgresql::server::extension { "${postgres_database_name}-pg_trgm":
      extension => 'pg_trgm',
      database  => $postgres_database_name,
    }

    # Class['puppetdb::database::postgresql'] is declared inside Class['puppetdb']
    Class['lsys_postgresql'] -> Class['puppetdb::database::postgresql']
  }

  if $manage_cron {
    include puppetdb::params
    $automatic_dlo_cleanup = $puppetdb::params::automatic_dlo_cleanup
  }
  else {
    $automatic_dlo_cleanup = false
  }

  $ssl_dir = assert_type(Stdlib::Unixpath, $puppet::params::puppetdb_ssl_dir)

  class { 'puppetdb':
    manage_dbserver       => false,
    database_host         => $postgres_database_host,
    database_name         => $postgres_database_name,
    database_username     => $postgres_database_username,
    database_password     => $postgres_database_password,
    manage_firewall       => $manage_firewall,

    manage_database       => $manage_database,

    ssl_deploy_certs      => $ssl_deploy_certs,
    ssl_set_cert_paths    => true,

    ssl_protocols         => join($ssl_protocols, ','),
    cipher_suites         => join($cipher_suites, ','),

    automatic_dlo_cleanup => $automatic_dlo_cleanup,
    confdir               => $puppet::params::puppetdb_confdir,
    ssl_dir               => $puppet::params::puppetdb_ssl_dir,
    vardir                => $puppet::params::puppetdb_vardir,
    ssl_key_path          => "${ssl_dir}/private.pem",
    ssl_cert_path         => "${ssl_dir}/public.pem",
    ssl_ca_cert_path      => "${ssl_dir}/ca.pem",
  }
  contain puppetdb

  # Ubuntu 24.04
  if $puppet::params::compat_mode {
    include puppet::puppetdb::compat
  }

  unless $ssl_deploy_certs {
    include puppet::puppetdb::https_config
  }
}
