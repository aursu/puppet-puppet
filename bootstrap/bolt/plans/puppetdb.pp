plan puppet_bootstrap::puppetdb (
  TargetSpec $targets = 'puppetdb',
  Stdlib::Fqdn $puppet_server = 'puppet',
  Puppet::Platform $platform_name = 'puppet8',
  Boolean $manage_database = true,
  Stdlib::Host $database_host = 'localhost',
  String $database_name = 'puppetdb',
  String $database_username = 'puppetdb',
  String $database_password = 'puppetdb',
  Boolean $manage_firewall = false,
  Optional[String] $certname = undef,
) {
  run_plan(facts, $targets)

  # Unable to connect to puppetdb server (https://puppet-puppet-puppetdb-1:8081):
  # Server hostname 'puppet-puppet-puppetdb-1' did not match server certificate;
  # expected one of e7475213c9fe, DNS:e7475213c9fe
  run_plan( puppet_bootstrap::puppetdb::node, $targets,
    puppet_server => $puppet_server,
    certname      => $certname,
    platform_name => $platform_name,
  )

  return apply($targets) {
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

    class { 'puppet::profile::puppetdb':
      platform_name     => $platform_name,
      manage_database   => $manage_database,
      database_host     => $postgres_database_host,
      database_name     => $postgres_database_name,
      database_username => $postgres_database_username,
      database_password => $postgres_database_password,
      manage_firewall   => $manage_firewall,
      manage_cron       => false,
    }
  }
}
