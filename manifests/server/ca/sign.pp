# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   puppet::server::ca::sign { 'namevar': }
define puppet::server::ca::sign (
  String $certname = $name,
)
{
  include puppet::params

  $csrdir = $puppet::params::csrdir
  $signeddir = $puppet::params::signeddir

  exec { "puppetserver ca sign --certname ${certname}":
    path    => '/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/bin:/usr/bin',
    onlyif  => "test -f ${csrdir}/${certname}.pem",
    creates => "${signeddir}/${certname}.pem",
  }
}

