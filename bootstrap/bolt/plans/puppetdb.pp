plan puppet_bootstrap::puppetdb (
  TargetSpec $targets,
  Boolean $manage_database = true,
  Stdlib::Host $postgres_database_host = 'localhost',
  String $postgres_database_name = 'puppetdb',
  String $postgres_database_username = 'puppetdb',
  String $postgres_database_password = 'puppetdb',
  # According to moz://a SSL Configuration Generator for jetty 10.0.20, intermediate config
  Array[String] $ssl_protocols = ['TLSv1.2', 'TLSv1.3'],
  Array[String] $cipher_suites = [
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
  Boolean $manage_firewall = false,
) {
  run_plan(facts, $targets)

  run_plan( puppet::agent::install, $targets,
    collection => $platform_name,
  )

  return apply($targets) {
    include puppet

    class { 'puppet::puppetdb':
      manage_database            => $manage_database,
      postgres_database_host     => $postgres_database_host,
      postgres_database_name     => $postgres_database_name,
      postgres_database_username => $postgres_database_username,
      postgres_database_password => $postgres_database_password,
      ssl_protocols              => $puppetdb_ssl_protocols,
      cipher_suites              => $puppetdb_cipher_suites,
      manage_firewall            => $manage_firewall,
    }
  }
}
