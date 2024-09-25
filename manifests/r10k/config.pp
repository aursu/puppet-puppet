# @summary Default r10k configuration file
#
# The r10k configuration file is created only if r10k.yaml does not already
# exist. By default, it establishes the `production` environment. Optionally,
# it can also configure `common` and `enc` environments.
#
# @param r10k_config_setup
#   Determines the management strategy for the r10k configuration file: whether
#   to update it on each notify event or to only create it if it does not
#   already exist.
#
# @param r10k_yaml_template
#   Allows the specification of a custom r10k.yaml ERB (Embedded Ruby) template for setup,
#   instead of using the default template provided.
#
# @param cachedir
#   This parameter allows for the customization of the r10k cache directory path,
#   aligning with the `cachedir` parameter specified inside the r10k configuration.
#
# @param environmentpath
#   Specifies the directory path to Puppet environments. This parameter
#   corresponds to the `basedir` parameter for each source defined in the r10k
#   configuration.
#
# @param production_remote
#   Sets the Git repository URL for the `production` environment. This setting aligns
#   with the `remote` parameter designated for the `production` source in the r10k
#   configuration. The default URL is https://github.com/aursu/control-init.git.
#
# @param use_common_env
#   Determines whether to setup the `common` environment.
#
# @param common_remote
#   Sets the Git repository URL for the `common` environment. This setting aligns
#   with the `remote` parameter designated for the `common` source in the r10k
#   configuration. The default URL is https://github.com/aursu/control-common.git.
#
# @param use_enc
#   Determines whether to setup the `enc` environment.
#
# @param enc_remote
#   Sets the Git repository URL for the `enc` environment. This setting aligns
#   with the `remote` parameter designated for the `enc` source in the r10k
#   configuration. The default URL is https://github.com/aursu/control-enc.git.
#
# @example
#   include puppet::r10k::config
#
class puppet::r10k::config (
  String  $r10k_yaml_template = $puppet::r10k_yaml_template,
  Stdlib::Absolutepath $cachedir = $puppet::globals::r10k_cachedir,
  Stdlib::Absolutepath $environmentpath = $puppet::params::environmentpath,
  Boolean $r10k_config_setup = $puppet::r10k_config_setup,
  String  $production_remote = $puppet::production_remote,
  Boolean $use_common_env = $puppet::use_common_env,
  String  $common_remote = $puppet::common_remote,
  Boolean $use_enc = $puppet::use_enc,
  String  $enc_remote = $puppet::enc_remote,
) inherits puppet::globals {
  include puppet::r10k::setup

  # /opt/puppetlabs/puppet/cache/r10k
  $r10k_vardir = $puppet::params::r10k_vardir
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
