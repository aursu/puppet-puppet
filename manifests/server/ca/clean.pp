# @summary Puppet certificate cleanup call
#
# Puppet certificate cleanup call
#
# @param certname
#   Certificate name for which run `puppetserver ca clean` command
#
# @example
#   puppet::server::ca::clean { 'namevar': }
define puppet::server::ca::clean (
  String $certname = $name,
)
{
  include puppet::params
  $signeddir = $puppet::params::signeddir

  exec { "puppetserver ca clean --certname ${certname}":
    path   => '/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/bin:/usr/bin',
    onlyif => "test -f ${signeddir}/${certname}.pem",
  }
}
