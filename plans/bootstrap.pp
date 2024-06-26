plan puppet::bootstrap (
  TargetSpec $targets,
  Stdlib::Fqdn $server,
  Optional[String] $certname = undef,
  Puppet::Platform $collection = 'puppet8',
) {
  run_plan(puppet::agent::install, $targets, collection => $collection)
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet
    class { 'puppet::agent::config':
      server   => $server,
      certname => $certname,
    }
    class { 'puppet::agent::bootstrap':
      require => Class['puppet::agent::config'],
    }
  }
}
