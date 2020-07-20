# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
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
