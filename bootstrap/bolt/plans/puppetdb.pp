plan puppet_bootstrap::puppetdb (
  TargetSpec $targets,
  Puppet::Platform $platform_name = 'puppet8',
  Boolean $manage_database = true,
  Stdlib::Host $database_host = 'localhost',
  String $database_name = 'puppetdb',
  String $database_username = 'puppetdb',
  String $database_password = 'puppetdb',
  Boolean $manage_firewall = false,
) {
  run_plan(facts, $targets)

  run_plan( puppet::agent::install, $targets,
    collection => $platform_name,
  )

  return apply($targets) {
    include puppet

    $postgres_database_host = lookup({ name => 'puppet::puppetdb::postgres_database_host',
        value_type => Stdlib::Host, default_value => $database_host,
    })

    $postgres_database_name = lookup({ name => 'puppet::puppetdb::postgres_database_name',
        value_type => String, default_value => $database_name,
    })

    $postgres_database_username = lookup({ name => 'puppet::puppetdb::postgres_database_username',
        value_type => String, default_value => $database_username,
    })

    $postgres_database_password = lookup({ name => 'puppet::puppetdb::postgres_database_password',
        value_type => String, default_value => $database_password,
    })

    class { 'puppet::puppetdb':
      manage_database            => $manage_database,
      postgres_database_host     => $postgres_database_host,
      postgres_database_name     => $postgres_database_name,
      postgres_database_username => $postgres_database_username,
      postgres_database_password => $postgres_database_password,
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
    }
  }
}
