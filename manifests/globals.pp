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
  Boolean $os_vendor_distro = true,
  Boolean $compat_mode = $puppet::params::compat_mode,
) inherits puppet::params {
  $os_name          = $puppet::params::os_name
  $version_codename = $puppet::params::version_codename
  $clientcert       = $puppet::params::clientcert
  $tmpdir           = $puppet::params::tmpdir

  if $os_vendor_distro {
    $puppet_platform_distro = $puppet::params::puppet_platform_distro
  }
  else {
    $puppet_platform_distro = true
  }

  if $puppet_platform_distro {
    $server_confdir    = '/etc/puppetlabs/puppetserver'
    $vardir            = '/opt/puppetlabs/server/data/puppetserver'
    $logdir            = '/var/log/puppetlabs/puppetserver'
    $rundir            = '/var/run/puppetlabs/puppetserver'
    $install_dir       = '/opt/puppetlabs/server/apps/puppetserver'
    $codedir           = '/etc/puppetlabs/code'
    $confdir           = '/etc/puppetlabs/puppet'
    $puppet_path       = '/opt/puppetlabs/puppet/bin/puppet'
    $gem_path          = '/opt/puppetlabs/puppet/bin/gem'
    $ruby_path         = '/opt/puppetlabs/puppet/bin/ruby'
    $r10k_package_provider = 'puppet_gem'
    $r10k_path             = '/opt/puppetlabs/puppet/bin/r10k'

    $agent_version = 'installed'
    $server_version = 'installed'
    $puppetdb_version = 'installed'
  }
  else {
    $server_confdir    = '/etc/puppet/puppetserver'
    $vardir            = '/var/lib/puppetserver'
    $logdir            = '/var/log/puppetserver'
    $rundir            = '/var/run/puppetserver'
    $install_dir       = '/usr/share/puppetserver'
    $codedir           = '/etc/puppet/code'
    $confdir           = '/etc/puppet'
    $puppet_path       = '/usr/bin/puppet'
    $gem_path          = '/usr/bin/gem'
    $ruby_path         = '/usr/bin/ruby'
    $r10k_package_provider = 'gem'
    $r10k_path             = '/usr/local/bin/r10k'

    $agent_version = '8.4.0-1'
    $server_version = '8.4.0-1'
    $puppetdb_version = '7.12.1-3'
  }

  $repo_name        = "${platform_name}-release"

  $puppet_config    = "${confdir}/puppet.conf"
  $server_gem_home  = "${vardir}/jruby-gems"

  $config              = "${server_confdir}/conf.d"
  $bootstrap_config    = "${server_confdir}/services.d"
  $pidfile             = "${rundir}/puppetserver.pid"

  if $facts['puppet_ssldir'] {
    $ssldir = $facts['puppet_ssldir']
  }
  else {
    $ssldir = "${confdir}/ssl"
  }

  # Client authentication
  if $facts['puppet_sslpaths'] {
    $certdir       = $facts['puppet_sslpaths']['certdir']['path']
    $privatekeydir = $facts['puppet_sslpaths']['privatekeydir']['path']
    $requestdir    = $facts['puppet_sslpaths']['requestdir']['path']
    $publickeydir  = $facts['puppet_sslpaths']['publickeydir']['path']
  }
  else {
    # fallback to predefined
    $certdir       = "${ssldir}/certs"
    $privatekeydir = "${ssldir}/private_keys"
    $requestdir    = "${ssldir}/certificate_requests"
    $publickeydir  = "${ssldir}/public_keys"
  }

  $localcacert   = "${certdir}/ca.pem"
  $hostcrl       = "${ssldir}/crl.pem"
  $hostcert      = "${certdir}/${clientcert}.pem"
  $hostprivkey   = "${privatekeydir}/${clientcert}.pem"
  $hostpubkey    = "${publickeydir}/${clientcert}.pem"
  $hostreq       = "${requestdir}/${clientcert}.pem"

  # environmentpath
  # A search path for directory environments, as a list of directories
  # separated by the system path separator character. (The POSIX path
  # separator is ':', and the Windows path separator is ';'.)
  # This setting must have a value set to enable directory environments. The
  # recommended value is $codedir/environments. For more details,
  # see https://docs.puppet.com/puppet/latest/environments.html
  # Default: $codedir/environments

  $environmentpath     = "${codedir}/environments"

  $decommission_packages = ['puppet5-release', 'puppet6-release', 'puppet7-release', 'puppet8-release'] - [$repo_name]

  # https://www.puppet.com/docs/puppet/7/install_puppet.html#enable_the_puppet_platform_repository
  case $facts['os']['family'] {
    'Suse': {
      $repo_urlbase = 'https://yum.puppet.com'
      $repo_filename = "${repo_name}-${version_codename}.noarch.rpm"
    }
    'Debian': {
      $repo_urlbase = 'https://apt.puppet.com'

      # Ubuntu 24.04
      if $puppet::params::compat_mode {
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
