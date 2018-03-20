# puppet::setup::server
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::setup::server
class puppet::setup::server (
    Stdlib::Absolutepath
            $r10k_path           = $puppet::params::r10k_path,
) inherits puppet::params
{
    include puppet::install::r10k

    exec { 'environment-setup':
        command => "${r10k_path} deploy environment -p",
        require => Exec['r10k-installation'],
    }
}
