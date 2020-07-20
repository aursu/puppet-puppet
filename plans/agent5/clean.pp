plan puppet::agent5::clean (
  TargetSpec $targets,
) {
  run_plan(puppet::agent5::install, $targets)
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet
    class { 'puppet::agent::ssl::clean': }
  }
}
