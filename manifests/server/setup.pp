# puppet::setup::server
#
# This class setup dynamic environments using r10k invocation. If r10k is not
# configured, than it will setup it from template
#
# @summary Puppet server environment setup
#
# @example
#   include puppet::setup::server
class puppet::server::setup (
    Boolean $r10k_config_setup  = $puppet::r10k_config_setup,
    String  $r10k_yaml_template = $puppet::r10k_yaml_template,
    String  $production_remote  = $puppet::production_remote,
    Boolean $use_common_env     = $puppet::use_common_env,
    String  $common_remote      = $puppet::common_remote,
    Boolean $use_enc            = $puppet::use_enc,
    String  $enc_remote         = $puppet::enc_remote,
    Stdlib::Absolutepath
            $cachedir           = $puppet::r10k_cachedir,
    Stdlib::Absolutepath
            $r10k_config_file   = $puppet::params::r10k_config_file,
    Stdlib::Absolutepath
            $r10k_path          = $puppet::params::r10k_path,
    Stdlib::Absolutepath
            $environmentpath    = $puppet::params::environmentpath,
    Stdlib::Absolutepath
            $eyaml_keys_path    = $puppet::params::eyaml_keys_path,
    String  $eyaml_public_key   = $puppet::params::eyaml_public_key,
    String  $eyaml_private_key  = $puppet::params::eyaml_private_key,
    Boolean $setup_on_each_run  = $puppet::environment_setup_on_each_run,
) inherits puppet::params
{
    include puppet::agent::install
    include puppet::r10k::install

    # /opt/puppetlabs/puppet/cache/r10k
    $r10k_vardir = "${facts['puppet_vardir']}/r10k"
    exec { 'r10k-vardir':
        command => "mkdir -p ${r10k_vardir}",
        creates => $r10k_vardir,
        path    => '/bin:/usr/bin',
        require => Package['puppet-agent'],
    }

    # this should be one time installation
    file { "${r10k_vardir}/r10k.yaml":
        content => template($r10k_yaml_template),
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
        notify  => Exec['r10k-config'],
        require => Exec['r10k-vardir'],
    }

    $r10k_config_path = dirname($r10k_config_file)
    # exec in order to avoid conflict with r10k module
    exec { 'r10k-confpath-setup':
        command => "mkdir -p ${r10k_config_path}",
        creates => $r10k_config_path,
        path    => '/bin:/usr/bin',
        require => Package['puppet-agent'],
    }

    if $r10k_config_setup {
        # only if ${r10k_vardir}/r10k.yaml just created or changed
        exec { 'r10k-config':
            command     => "cp ${r10k_vardir}/r10k.yaml ${r10k_config_file}",
            refreshonly => true,
            path        => '/bin:/usr/bin',
            require     => [
                File["${r10k_vardir}/r10k.yaml"],
                Exec['r10k-confpath-setup'],
            ],
        }
    }
    else {
        # only if config file not exists
        exec { 'r10k-config':
            command => "cp ${r10k_vardir}/r10k.yaml ${r10k_config_file}",
            creates => $r10k_config_file,
            path    => '/bin:/usr/bin',
            require => [
                File["${r10k_vardir}/r10k.yaml"],
                Exec['r10k-confpath-setup'],
            ],
        }
    }

    exec { 'environment-setup':
        command     => "${r10k_path} deploy environment -p",
        cwd         => '/',
        refreshonly => !$setup_on_each_run,
        path        => '/bin:/usr/bin',
        require     => Exec['r10k-installation'],
        subscribe   => Exec['r10k-config'],
    }

    # Hardening of Hiera Eyaml keys
    file { $eyaml_keys_path:
        ensure  => directory,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '0500',
        require => Package['puppet-agent'],
    }

    # poka-yoke
    if '/etc/puppetlabs/puppet/' in $eyaml_keys_path {
        File <| title == $eyaml_keys_path |> {
            recurse => true,
            purge   => true,
        }
    }

    [ $eyaml_public_key,
      $eyaml_private_key ].each |$key| {
        file { "${eyaml_keys_path}/${key}":
            owner => 'puppet',
            group => 'puppet',
            mode  => '0400',
        }
    }
}
