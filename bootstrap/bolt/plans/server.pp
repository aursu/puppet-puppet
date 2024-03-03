plan puppet_bootstrap::server (
  TargetSpec $targets = 'puppetservers',
  Puppet::Platform $platform_name = 'puppet8',
) {
  run_plan(facts, $targets)

  run_plan( puppet::agent::install, $targets,
    collection => $platform_name
  )

  return run_plan( puppet::server::bootstrap, $targets,
    collection             => $platform_name,
    access_data_lookup_key => 'puppet::server::bootstrap::access',
    ssh_config_lookup_key  => 'puppet::server::bootstrap::ssh_config',
  )
}
