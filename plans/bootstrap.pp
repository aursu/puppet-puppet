plan puppet::bootstrap (
  TargetSpec $targets,
  Stdlib::Fqdn $server,
  Optional[String] $certname = undef,
  Puppet::Platform $collection = 'puppet8',
) {
  get_targets($targets).each |$target| {
    run_plan(puppet::agent::install, $target, collection => $collection)
    run_plan(facts, $target)

    $apply_results = apply($target) {
      class { 'puppet::globals':
        platform_name => $collection,
      }

      include puppet

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
  }
}
