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
      $manage_user = false
      $manage_apt = false
    }
    'Debian': {
      $version_codename = $facts['os']['distro']['codename']
      $package_provider = 'dpkg'
      $package_build = "1${version_codename}"
      $init_config_path = '/etc/default/puppetserver'
      $manage_user = true
      $user_id = undef
      $group_id = undef
      $user_shell = '/usr/sbin/nologin'
      $manage_apt = true
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
      $manage_user = true
      $user_id = 52
      $group_id = 52
      $user_shell = '/sbin/nologin'
      $manage_apt = false
    }
  }

  # if $os_name == 'Ubuntu' and $version_codename == 'noble' {
  #   $puppet_platform_distro = false
  #   $compat_mode = true
  #   # OS vendor's distribution packages (18/12/2024)
  #   $agent_version = '8.4.0-1'
  #   $server_version = '8.4.0-1'
  #   $puppetdb_version = '7.12.1-3'
  # }
  # else {
  #   $puppet_platform_distro = true
  #   $compat_mode = false
  #   $agent_version = 'installed'
  #   $server_version = 'installed'
  #   $puppetdb_version = 'installed'
  # }

  $puppet_platform_distro = true
  $compat_mode = false
  $agent_version = 'installed'
  $server_version = 'installed'
  $puppetdb_version = 'installed'

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

  $agent_package_name  = 'puppet-agent'
  $server_package_name = 'puppetserver'
  $r10k_package_name   = 'r10k'
  $r10k_cachedir       = '/var/cache/r10k'
  $service_name        = 'puppetserver'
  $r10k_config_file    = '/etc/puppetlabs/r10k/r10k.yaml'
  $eyaml_keys_path     = '/etc/puppetlabs/puppet/keys'
  $eyaml_public_key    = 'public_key.pkcs7.pem'
  $eyaml_private_key   = 'private_key.pkcs7.pem'

  $puppet_sbin         = '/opt/puppetlabs/bin/puppetserver'

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

  # https://www.puppet.com/docs/puppet/7/lang_facts_builtin_variables.html#lang_facts_builtin_variables-agent-facts
  if $facts['clientcert'] {
    $clientcert    = $facts['clientcert']
  }
  else {
    # fallback to fqdn
    $clientcert    = $facts['networking']['fqdn']
  }

  $r10k_vardir = "${facts['puppet_vardir']}/r10k"
}
