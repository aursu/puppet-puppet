plan puppet::bootstrap (
  TargetSpec $targets,
  Stdlib::Fqdn
            $server,
  Puppet::Platform $collection = 'puppet7',
) {
  run_plan(puppet::agent::install, $targets, collection => $collection)
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet
    class { 'puppet::agent::config':
      server => $server,
    }
    class { 'puppet::agent::bootstrap':
      require => Class['puppet::agent::config'],
    }
  }
}
