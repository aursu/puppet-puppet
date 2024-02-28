plan puppet::agent::install (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet8',
) {
  return run_task('puppet_agent::install', $targets, collection => $collection, stop_service => true)
}
