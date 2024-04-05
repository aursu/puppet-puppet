plan puppet_bootstrap::server (
  TargetSpec $targets = 'puppetservers',
  Puppet::Platform $platform_name = 'puppet8',
  Stdlib::Unixpath $bootstrap_path = '/root/bootstrap',
  Boolean $git_use_ssh = true,
  Optional[String] $certname = undef,
  Optional[String] $dns_alt_names = undef,
) {
  run_plan( puppet::agent::install, $targets,
    collection => $platform_name,
  )

  run_plan(facts, $targets)

  run_plan( bootstrap_assets::upload, $targets,
    path => $bootstrap_path,
  )

  return run_plan( puppet::server::bootstrap, $targets,
    collection             => $platform_name,
    access_data_lookup_key => 'puppet::server::bootstrap::access',
    ssh_config_lookup_key  => 'puppet::server::bootstrap::ssh_config',
    bootstrap_path         => $bootstrap_path,
    use_ssh                => $git_use_ssh,
    certname               => $certname,
    dns_alt_names          => $dns_alt_names,
  )
}
