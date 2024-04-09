# PuppetDB Node Bootstrap
#
# Submits a certificate request to the Puppet server, signs it on the Puppet server, and downloads
# it onto the PuppetDB node.
#
plan puppet_bootstrap::puppetdb::node (
  TargetSpec $targets = 'puppetdb',
  Stdlib::Fqdn $puppet_server = 'puppet',
  Optional[String] $certname = undef,
  Puppet::Platform $platform_name = 'puppet8',
) {
  # Submit a certificate request to the Puppet server
  run_plan( puppet::bootstrap, $targets,
    server     => $puppet_server,
    certname   => $certname,
    collection => $platform_name,
  )

  # Sign certificate request on the Puppet server
  run_plan( puppet::cert::sign, $targets,
    server   => $puppet_server,
    certname => $certname,
  )

  # download certificate onto the PuppetDB node.
  run_plan( puppet::bootstrap, $targets,
    server   => $puppet_server,
    certname => $certname,
  )
}
