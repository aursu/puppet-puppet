plan puppet::agent::clean (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet8',
) {
  run_plan(puppet::agent::install, $targets, collection => $collection)
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet
    class { 'puppet::agent::ssl::clean': }
  }
}
