plan puppet::agent::install (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet8',
) {
  run_task(bsys::install_yum, $targets)
  if $collection in ['puppet7', 'puppet8'] {
    return run_task('puppet_agent::install', $targets,
      collection   => $collection,
      stop_service => true,
    )
  } else {
    return run_task('openvox_bootstrap::install', $targets,
      collection   => $collection,
      stop_service => true,
    )
  }
}
