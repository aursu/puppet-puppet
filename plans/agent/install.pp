plan puppet::agent::install (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet8',
) {
  run_task(bsys::install_yum, $targets)
  return run_task(puppet_agent::install, $targets, collection => $collection, stop_service => true)
}
