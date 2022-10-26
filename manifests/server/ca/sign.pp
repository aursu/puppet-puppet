# @summary Puppet certificate sign
#
# Puppet certificate sign
#
# @param certname
#   Certificate name, for which run command `puppetserver ca sign`
#
# @example
#   puppet::server::ca::sign { 'namevar': }
define puppet::server::ca::sign (
  String $certname = $name,
) {
  include puppet::globals

  $csrdir = $puppet::globals::csrdir
  $signeddir = $puppet::globals::signeddir

  exec { "puppetserver ca sign --certname ${certname}":
    path    => '/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/bin:/usr/bin',
    onlyif  => "test -f ${csrdir}/${certname}.pem",
    creates => "${signeddir}/${certname}.pem",
  }
}
