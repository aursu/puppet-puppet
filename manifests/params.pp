# puppet::params
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::params
class puppet::params {
  include bsys::params
  include puppetdb::params

  $tmpdir = '/tmp/puppet-puppet'

  $os_version = $bsys::params::osmaj
  $os_name = $bsys::params::osname

  if $facts['mountpoints'] and $facts['mountpoints']['/tmp'] {
    $tmp_mountpoint_noexec = ('noexec' in $facts['mountpoints']['/tmp']['options'])
  }
  else {
    $tmp_mountpoint_noexec = false
  }

  case $facts['os']['family'] {
    'Suse': {
      $os_abbreviation  = 'sles'
      $version_codename = "${os_abbreviation}-${os_version}"
      $package_provider = 'rpm'
      $package_build = "1.sles${os_version}"
      $init_config_path = '/etc/sysconfig/puppetserver'
      $debian = false
      $manage_user = false
    }
    'Debian': {
      $version_codename = $facts['os']['distro']['codename']
      $package_provider = 'dpkg'
      $package_build = "1${version_codename}"
      $init_config_path = '/etc/default/puppetserver'
      $debian = true
      $manage_user = true
      $user_id = undef
      $group_id = undef
      $user_shell = '/usr/sbin/nologin'
    }
    # default is RedHat based systems
    default: {
      case $os_name {
        'Fedora': {
          $os_abbreviation = 'fedora'
          $package_build = "1.fc${os_version}"
        }
        default: {
          $os_abbreviation = 'el'
          $package_build = "1.el${os_version}"
        }
      }
      $version_codename = "${os_abbreviation}-${os_version}"
      $package_provider = 'rpm'
      # init config
      $init_config_path = '/etc/sysconfig/puppetserver'
      $debian = false
      $manage_user = true
      $user_id = 52
      $group_id = 52
      $user_shell = '/sbin/nologin'
    }
  }

  if $os_name == 'Ubuntu' and $version_codename == 'noble' {
    # Ubuntu 24.04
    $puppet_platform_distro = false
    $puppetdb_terminus_package = 'puppet-terminus-puppetdb'
  }
  else {
    $puppet_platform_distro = true
    $puppetdb_terminus_package = $puppetdb::params::terminus_package
  }

  # Whether to enable and manage Puppet platform repository
  $manage_repo = $puppet_platform_distro

  case $os_name {
    'CentOS', 'Rocky': {
      if $os_version in ['6', '7'] {
        $manage_init_config   = false # not implemented
        $init_config_template = undef
      }
      else {
        $manage_init_config = true
        $init_config_template = 'puppet/init/puppetserver.epp'
      }
    }
    'Ubuntu': {
      $manage_init_config = true
      $init_config_template = 'puppet/init/puppetserver.epp'
    }
    default: {
      $manage_init_config   = false # not implemented
      $init_config_template = undef
    }
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
  }

  $puppet_config       = "${confdir}/puppet.conf"

  $server_gem_home     = "${vardir}/jruby-gems"
  $agent_package_name  = 'puppet-agent'
  $server_package_name = 'puppetserver'
  $r10k_package_name   = 'r10k'
  $r10k_cachedir       = '/var/cache/r10k'
  $service_name        = 'puppetserver'
  $r10k_config_file    = '/etc/puppetlabs/r10k/r10k.yaml'
  $eyaml_keys_path     = '/etc/puppetlabs/puppet/keys'
  $eyaml_public_key    = 'public_key.pkcs7.pem'
  $eyaml_private_key   = 'private_key.pkcs7.pem'

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

  # --config /etc/puppet/puppetserver/conf.d
  $config              = "${server_confdir}/conf.d"
  # --bootstrap-config /etc/puppet/puppetserver/services.d
  $bootstrap_config    = "${server_confdir}/services.d"
  $puppet_sbin         = '/opt/puppetlabs/bin/puppetserver'
  $pidfile             = "${rundir}/puppetserver.pid"

  # environmentpath
  # A search path for directory environments, as a list of directories
  # separated by the system path separator character. (The POSIX path
  # separator is ':', and the Windows path separator is ';'.)
  # This setting must have a value set to enable directory environments. The
  # recommended value is $codedir/environments. For more details,
  # see https://docs.puppet.com/puppet/latest/environments.html
  # Default: $codedir/environments

  $environmentpath     = "${codedir}/environments"

  # external_nodes
  # The external node classifier (ENC) script to use for node data. Puppet
  # combines this data with the main manifest to produce node catalogs.
  # To enable this setting, set the node_terminus setting to exec.
  # This setting’s value must be the path to an executable command that can
  # produce node information. The command must:
  #   * Take the name of a node as a command-line argument.
  #   * Return a YAML hash with up to three keys:
  #       - classes — A list of classes, as an array or hash.
  #       - environment — A string.
  #       - parameters — A list of top-scope variables to set, as a hash.
  #   * For unknown nodes, exit with a non-zero exit code.
  # Generally, an ENC script makes requests to an external data source.
  # For more info, see the ENC documentation.
  # Default: none

  $external_nodes      = '/usr/local/bin/puppet_node_classifier'

  $localcacert   = "${certdir}/ca.pem"
  $hostcrl       = "${ssldir}/crl.pem"

  # https://www.puppet.com/docs/puppet/7/lang_facts_builtin_variables.html#lang_facts_builtin_variables-agent-facts
  if $facts['clientcert'] {
    $clientcert    = $facts['clientcert']
  }
  else {
    # fallback to fqdn
    $clientcert    = $facts['networking']['fqdn']
  }

  $hostcert      = "${certdir}/${clientcert}.pem"
  $hostprivkey   = "${privatekeydir}/${clientcert}.pem"
  $hostpubkey    = "${publickeydir}/${clientcert}.pem"
  $hostreq       = "${requestdir}/${clientcert}.pem"

  $r10k_vardir = "${facts['puppet_vardir']}/r10k"
}
