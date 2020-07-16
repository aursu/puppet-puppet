plan puppet::bootstrap (
  TargetSpec $targets,
  Stdlib::Fqdn
            $master,
) {
  run_plan(puppet::agent5::install, $targets)
  run_plan(facts, $targets)

  apply($targets) {
    class { 'puppet::agent::config':
      server => $master,
    }
  }
}
