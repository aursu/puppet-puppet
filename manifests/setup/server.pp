# puppet::setup::server
#
# This class setup dynamic environments using r10k invocation. If r10k is not
# configured, than it will setup it from template
#
# @summary Setup r10k dynamic environments
#
# @example
#   include puppet::setup::server
class puppet::setup::server (
    String  $r10k_yaml_template = $puppet::r10k_yaml_template,
    String  $production_remote  = $puppet::production_remote,
    Boolean $use_common_env     = $puppet::use_common_env,
    String  $common_remote      = $puppet::common_remote,
    Boolean $use_enc            = $puppet::use_enc,
    String  $enc_remote         = $puppet::enc_remote,
    Stdlib::Absolutepath
            $r10k_config_file   = $puppet::params::r10k_config_file,
    Stdlib::Absolutepath
            $r10k_path          = $puppet::params::r10k_path,
    Stdlib::Absolutepath
            $environmentpath    = $puppet::params::environmentpath,
) inherits puppet::params
{
    include puppet::install::agent
    include puppet::install::r10k

    Exec {
        path => '/bin:/usr/bin',
    }

    # this should be one time installation
    file { '/tmp/r10k.yaml':
        content => template($r10k_yaml_template),
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
    }

    $r10k_config_path = dirname($r10k_config_file)
    exec { "mkdir -p ${r10k_config_path}":
        creates => $r10k_config_path,
        require => Package['puppet-agent'],
        alias   => 'r10k-confpath-setup',
    }

    exec { "cp /tmp/r10k.yaml ${r10k_config_file}":
        creates => $r10k_config_file,
        require => [
            File['/tmp/r10k.yaml'],
            Exec['r10k-confpath-setup'],
        ],
        alias   => 'r10k-config',
    }

    exec { 'environment-setup':
        command => "${r10k_path} deploy environment -p",
        require => [
            Exec['r10k-installation'],
            Exec['r10k-config'],
        ],
    }
}
