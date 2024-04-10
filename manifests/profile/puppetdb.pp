# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @param manage_database
# @param database_host
# @param database_name
# @param database_username
# @param database_password
# @param manage_firewall
#
# @param manage_cron
#   Specifies whether to manage crontab entries. This setting is critical for
#   containerized environments where crontab may not be available.
#
# @example
#   include puppet::profile::puppetdb
class puppet::profile::puppetdb (
  Boolean $manage_database = true,
  Stdlib::Host $database_host = 'localhost',
  String $database_name = 'puppetdb',
  String $database_username = 'puppetdb',
  String $database_password = 'puppetdb',
  Boolean $manage_firewall = false,
  Boolean $manage_cron = true,
) {
  include puppet

  class { 'puppet::puppetdb':
    manage_database            => $manage_database,
    postgres_database_host     => $database_host,
    postgres_database_name     => $database_name,
    postgres_database_username => $database_username,
    postgres_database_password => $database_password,
    # According to moz://a SSL Configuration Generator for jetty 10.0.20, intermediate config
    ssl_protocols              => ['TLSv1.2', 'TLSv1.3'],
    cipher_suites              => [
      'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
      'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
      'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
      'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
      'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256',
      'TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256',
      'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
      'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256',
      'TLS_DHE_RSA_WITH_CHACHA20_POLY1305_SHA256',
    ],
    manage_firewall            => $manage_firewall,
    manage_cron                => $manage_cron,
  }
}
