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
  Puppet::Platform $platform_name = 'puppet8',
  Stdlib::Absolutepath $r10k_cachedir = $puppet::params::r10k_cachedir,
) inherits puppet::params {
  $package_name     = "${platform_name}-release"
  $version_codename = $puppet::params::version_codename
  $ssldir           = $puppet::params::ssldir
  $server_confdir   = $puppet::params::server_confdir
  $localcacert      = $puppet::params::localcacert
  $hostcrl          = $puppet::params::hostcrl
  $hostpubkey       = $puppet::params::hostpubkey
  $hostcert         = $puppet::params::hostcert
  $clientcert       = $puppet::params::clientcert
  $hostprivkey      = $puppet::params::hostprivkey

  $deccomission_packages = ['puppet5-release', 'puppet6-release', 'puppet7-release', 'puppet8-release'] - [$package_name]

  # https://www.puppet.com/docs/puppet/7/install_puppet.html#enable_the_puppet_platform_repository
  case $facts['os']['family'] {
    'Suse': {
      $repo_urlbase = 'https://yum.puppet.com'
      $package_filename = "${package_name}-${version_codename}.noarch.rpm"
    }
    'Debian': {
      $repo_urlbase = 'https://apt.puppet.com'
      $package_filename = "${package_name}-${version_codename}.deb"
    }
    # default is RedHat based systems
    default: {
      $repo_urlbase = 'https://yum.puppet.com'
      $package_filename = "${package_name}-${version_codename}.noarch.rpm"
    }
  }

  $platform_repository = "${repo_urlbase}/${package_filename}"

  $cadir = $platform_name ? {
    'puppet5' => "${ssldir}/ca",
    'puppet6' => "${ssldir}/ca",
    default   => "${server_confdir}/ca",
  }
  $csrdir   = "${cadir}/requests"
  $signeddir = "${cadir}/signed"

  $cacert = "${cadir}/ca_crt.pem"
  $cakey  = "${cadir}/ca_key.pem"
  $capub  = "${cadir}/ca_pub.pem"
  $cacrl  = "${cadir}/ca_crl.pem"
  $signed_cert = "${signeddir}/${clientcert}.pem"
  $cert_inventory = "${cadir}/inventory.txt"
  $serial = "${cadir}/serial"
  # https://www.puppet.com/docs/puppet/7/server/infrastructure_crl.html
  $infra_crl = "${cadir}/infra_crl.pem"
  $infra_inventory = "${cadir}/infra_inventory.txt"
  $infra_serial = "${cadir}/infra_serials"

  $ca_public_files = [
    $cacert,
    $cacrl,
    $infra_crl,
    $localcacert,
    $hostcrl,
    $hostpubkey,
    $hostcert,
    $cert_inventory,
    $capub,
    $infra_inventory,
    $infra_serial,
    $signed_cert,
    $serial,
  ]

  $ca_private_files = [
    $hostprivkey,
    $cakey,
  ]

  $cert_generate_files = [
    $hostcert,
    $hostprivkey,
    $hostpubkey,
    $signed_cert,
  ]
}
