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
# @param postgres_database_host
#   PostgreSQL database hostname
#
# @param postgres_database_name
#   PostgreSQL database name for PuppetDB
#
# @param postgres_database_username
#   PostgreSQL database username for PuppetDB
#
# @param postgres_database_password
#   PostgreSQL database password for PuppetDB
#
# @param ssl_protocols
#   Array of SSL/TLS protocol versions to enable
#
# @param cipher_suites
#   Array of SSL/TLS cipher suites to enable
#
# @param ssl_client_auth
#   Whether the Jetty SSL connector requires a client certificate during the TLS
#   handshake — `need`, `want` or `none`, written as `ssl-client-auth` into
#   `jetty.ini`. Default is `undef`, which leaves the setting unmanaged and Jetty on
#   its own default. `need` rejects a client without a CA-signed certificate at the
#   handshake, before any `auth.conf` rule is consulted; combined with PuppetDB's
#   deny-by-default `auth.conf` that gives two enforcing layers.
#
#   `puppetlabs-puppetdb` does not manage this setting, so it is declared here as an
#   `ini_setting` alongside the ones the upstream module owns.
#
# @param ssl_listen_address
#   Address the Jetty SSL connector binds to, passed through to `puppetdb`. Default is
#   `127.0.0.1`, so the port is not offered to the network at all — this **deliberately
#   departs from the upstream default of `0.0.0.0`**. Where PuppetDB serves only the
#   Puppet Server on the same host, which is the common case, loopback is the correct
#   binding and needs no configuration.
#
#   ⚠ Set this to a reachable address for a **split topology** — a PuppetDB on its own
#   host, as in scenario 2 above — or the Puppet Server will not be able to reach it.
#   `0.0.0.0` restores the upstream behaviour.
#
#   Note this is passed to the `puppetdb` class unconditionally, which makes the
#   `puppetdb::ssl_listen_address` Hiera key inert — set `puppet::puppetdb::ssl_listen_address`
#   instead.
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
  Optional[Enum['need', 'want', 'none']] $ssl_client_auth = undef,
  Stdlib::IP::Address $ssl_listen_address = '127.0.0.1',
  Boolean $manage_firewall = false,
  Boolean $manage_cron = true,
  Boolean $ssl_deploy_certs = false,
) {
  include puppet::puppetdb::globals

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

  $ssl_dir = assert_type(Stdlib::Unixpath, $puppet::puppetdb::globals::ssl_dir)

  class { 'puppetdb':
    manage_dbserver       => false,
    database_host         => $postgres_database_host,
    database_name         => $postgres_database_name,
    database_username     => $postgres_database_username,
    database_password     => $postgres_database_password,
    manage_firewall       => $manage_firewall,

    manage_database       => $manage_database,

    puppetdb_package      => $puppet::puppetdb::globals::puppetdb_package,

    ssl_deploy_certs      => $ssl_deploy_certs,
    ssl_set_cert_paths    => true,

    ssl_listen_address    => $ssl_listen_address,
    ssl_protocols         => join($ssl_protocols, ','),
    cipher_suites         => join($cipher_suites, ','),

    automatic_dlo_cleanup => $automatic_dlo_cleanup,
    confdir               => $puppet::puppetdb::globals::confdir,
    ssl_dir               => $puppet::puppetdb::globals::ssl_dir,
    vardir                => $puppet::puppetdb::globals::vardir,
    ssl_key_path          => "${ssl_dir}/private.pem",
    ssl_cert_path         => "${ssl_dir}/public.pem",
    ssl_ca_cert_path      => "${ssl_dir}/ca.pem",
  }
  contain puppetdb

  # ssl-client-auth is not a setting puppetlabs-puppetdb manages, so it is declared
  # here. The upstream module writes jetty.ini with individual ini_setting resources
  # rather than from a template, so adding one does not fight it for ownership of the
  # file. Its Ini_setting resource defaults are scoped to puppetdb::server::jetty and
  # do not reach here, hence the explicit path and section.
  #
  # Ordering: after the jetty class so the file and its other settings are already in
  # place, and notifying the service so the change is picked up. Requiring the whole
  # puppetdb class instead would deadlock — the service is contained in it.
  if $ssl_client_auth {
    include puppetdb::params

    ini_setting { 'puppetdb_ssl_client_auth':
      ensure  => present,
      path    => "${puppet::puppetdb::globals::confdir}/jetty.ini",
      section => 'jetty',
      setting => 'ssl-client-auth',
      value   => $ssl_client_auth,
      require => Class['puppetdb::server::jetty'],
      notify  => Service[$puppetdb::params::puppetdb_service],
    }
  }

  include puppet::puppetdb::compat

  unless $ssl_deploy_certs {
    include puppet::puppetdb::https_config
  }
}
