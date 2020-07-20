plan puppet::bootstrap (
  TargetSpec $targets,
  Stdlib::Fqdn
            $server,
) {
  run_plan(puppet::agent5::install, $targets)
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
