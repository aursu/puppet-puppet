# puppet::enc
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::enc
class puppet::enc (
    String  $enc_template       = $puppet::enc_template,
    Optional[Stdlib::Absolutepath]
            $enc_data_source    = $puppet::enc_data_source,
    String  $enc_envname        = $puppet::enc_envname,
    Stdlib::Absolutepath
            $ruby_path          = $puppet::params::ruby_path,
    Stdlib::Absolutepath
            $external_nodes     = $puppet::params::external_nodes,
) inherits puppet::params
{
    include puppet::service

    file { $external_nodes:
        content => template($enc_template),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        alias   => 'enc-script',
        before  => Service['puppet-server']
    }
}