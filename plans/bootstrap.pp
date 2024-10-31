plan puppet::bootstrap (
  TargetSpec $targets,
  Stdlib::Fqdn $server,
  Optional[String] $certname = undef,
  Puppet::Platform $collection = 'puppet8',
) {
  run_plan(puppet::agent::install, $targets, collection => $collection)
  run_plan(facts, $targets)

  $apply_results = apply($targets) {
    include puppet

    class { 'puppet::globals':
      platform_name => $collection,
    }

    class { 'puppet::agent::config':
      server   => $server,
      certname => $certname,
    }

    class { 'puppet::agent::bootstrap':
      certname => $certname,
      require  => Class['puppet::agent::config'],
    }
  }

  # Print log messages from the report
  $apply_results.each |$result| {
    $result.report['logs'].each |$log| {
      out::message("${log['level'].capitalize}: ${log['source']}: ${log['message']}")
    }
  }

  return $apply_results
}
