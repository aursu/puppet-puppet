# @summary A short summary of the purpose of this class
#
# r10k configuration 
#
# @param r10k_config_setup
#   Decide whether to update the R10K configuration file each time it is required, or keep it to be
#   created only when it does not exist.
#
# @example
#   include puppet::r10k::config
class puppet::r10k::config (
  String  $r10k_yaml_template = $puppet::r10k_yaml_template,
  Stdlib::Absolutepath $cachedir = $puppet::params::r10k_cachedir,
  Stdlib::Absolutepath $environmentpath = $puppet::params::environmentpath,
  String  $production_remote = $puppet::production_remote,
  Boolean $use_common_env = $puppet::use_common_env,
  String  $common_remote = $puppet::common_remote,
  Boolean $use_enc = $puppet::use_enc,
  String  $enc_remote = $puppet::enc_remote,
  Boolean $r10k_config_setup = $puppet::r10k_config_setup,
) inherits puppet::params {
  include puppet::r10k::setup

  # /opt/puppetlabs/puppet/cache/r10k
  $r10k_vardir = "${facts['puppet_vardir']}/r10k"
  $r10k_config_file = $puppet::params::r10k_config_file

  # this should be one time installation
  file { "${r10k_vardir}/r10k.yaml":
    content => template($r10k_yaml_template),
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    notify  => Exec['r10k-config'],
  }

  if $r10k_config_setup {
    # only if ${r10k_vardir}/r10k.yaml just created or changed
    exec { 'r10k-config':
      command     => "cp ${r10k_vardir}/r10k.yaml ${r10k_config_file}",
      refreshonly => true,
      path        => '/bin:/usr/bin',
    }
  }
  else {
    # only if config file not exists
    exec { 'r10k-config':
      command => "cp ${r10k_vardir}/r10k.yaml ${r10k_config_file}",
      creates => $r10k_config_file,
      path    => '/bin:/usr/bin',
    }
  }

  Class['puppet::r10k::setup'] -> File["${r10k_vardir}/r10k.yaml"]
  Class['puppet::r10k::setup'] -> Exec['r10k-config']
}
