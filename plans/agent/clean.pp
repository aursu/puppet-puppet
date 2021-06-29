plan puppet::agent::clean (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet7',
) {
  run_plan(puppet::agent::install, $targets, $collection)
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet
    class { 'puppet::agent::ssl::clean': }
  }
}
