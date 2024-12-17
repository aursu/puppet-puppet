# @summary Module global settings
#
# Module global settings
#
# @param platform_name
# @param r10k_cachedir
#
# @example
#   include puppet::globals
class puppet::globals (
  Puppet::Platform $platform_name = 'puppet8',
  Stdlib::Absolutepath $r10k_cachedir = $puppet::params::r10k_cachedir,
  # String $agent_version = $puppet::agent_version,
  # String $server_version = $puppet::server_version,
) inherits puppet::params {
  $repo_name        = "${platform_name}-release"
  $version_codename = $puppet::params::version_codename
  $ssldir           = $puppet::params::ssldir
  $server_confdir   = $puppet::params::server_confdir
  $localcacert      = $puppet::params::localcacert
  $hostcrl          = $puppet::params::hostcrl
  $hostpubkey       = $puppet::params::hostpubkey
  $hostcert         = $puppet::params::hostcert
  $clientcert       = $puppet::params::clientcert
  $hostprivkey      = $puppet::params::hostprivkey
  $tmpdir           = $puppet::params::tmpdir
  $os_name          = $puppet::params::os_name

  $decommission_packages = ['puppet5-release', 'puppet6-release', 'puppet7-release', 'puppet8-release'] - [$repo_name]

  # Ubuntu 24.04
  # if $os_name == 'Ubuntu' and $version_codename == 'noble' and $agent_version in ['present', 'installed'] {
  #   $agent_package_version = '8.4.0-1'
  #   $server_package_version = '8.4.0-1'
  # }
  # else {
  #   $agent_package_version = $agent_version
  #   $server_package_version = $server_version
  # }

  # https://www.puppet.com/docs/puppet/7/install_puppet.html#enable_the_puppet_platform_repository
  case $facts['os']['family'] {
    'Suse': {
      $repo_urlbase = 'https://yum.puppet.com'
      $repo_filename = "${repo_name}-${version_codename}.noarch.rpm"
    }
    'Debian': {
      $repo_urlbase = 'https://apt.puppet.com'

      # Ubuntu 24.04
      if $os_name == 'Ubuntu' and $version_codename == 'noble' {
        $repo_filename = "${repo_name}-jammy.deb"
      }
      else {
        $repo_filename = "${repo_name}-${version_codename}.deb"
      }
    }
    # default is RedHat based systems
    default: {
      $repo_urlbase = 'https://yum.puppet.com'
      $repo_filename = "${repo_name}-${version_codename}.noarch.rpm"
    }
  }

  $platform_repository = "${repo_urlbase}/${repo_filename}"
  $repo_source = "${tmpdir}/${repo_filename}"

  case $facts['os']['family'] {
    'Debian': {
      $repo_check = "dpkg-deb --info ${repo_source}"
    }
    # default is RedHat based systems
    default: {
      $repo_check = "rpm --quiet -qip ${repo_source}"
    }
  }

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
