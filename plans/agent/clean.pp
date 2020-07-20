plan puppet::agent::clean (
  TargetSpec $targets,
) {
  run_plan(puppet::agent5::install, $targets)
  run_plan(facts, $targets)

  apply($targets) {
    include puppet
    class { 'puppet::agent::ssl::clean': }
  }
}
