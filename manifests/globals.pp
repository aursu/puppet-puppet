# @summary Module global settings
#
# Module global settings
#
# @example
#   include puppet::globals
#
# @param platform_name
#
class puppet::globals (
  Puppet::Platform $platform_name = 'puppet7',
) inherits puppet::params {
  $package_name     = "${platform_name}-release"
  $version_codename = $puppet::params::version_codename
  $ssldir           = $puppet::params::ssldir

  $deccomission_packages = ['puppet5-release', 'puppet6-release', 'puppet7-release'] - [$package_name]

  case $facts['os']['family'] {
    'Suse': {
      $repo_urlbase = "https://yum.puppet.com/${platform_name}"
      $package_filename = "${package_name}-${version_codename}.noarch.rpm"
    }
    'Debian': {
      $repo_urlbase = 'https://apt.puppetlabs.com'
      $package_filename = "${package_name}-${version_codename}.deb"
    }
    # default is RedHat based systems
    default: {
      $repo_urlbase = "https://yum.puppet.com/${platform_name}"
      $package_filename = "${package_name}-${version_codename}.noarch.rpm"
    }
  }

  $platform_repository = "${repo_urlbase}/${package_filename}"

  $cadir = $platform_name ? {
    'puppet5' => "${ssldir}/ca",
    'puppet6' => "${ssldir}/ca",
    default   => '/etc/puppetlabs/puppetserver/ca',
  }

  $cakey  = "${cadir}/ca_key.pem"
  $cacert = "${cadir}/ca_crt.pem"
  $cacrl  = "${cadir}/ca_crl.pem"
  $cert_inventory = "${cadir}/inventory.txt"
  $serial = "${cadir}/serial"
  $csrdir   = "${cadir}/requests"
  $signeddir = "${cadir}/signed"
}
