# puppet::install::r10k
#
# R10K installation on the server
#
# @summary R10K installation on the server
#
# @example
#   include puppet::install::r10k
class puppet::r10k::install (
    String  $r10k_package_name   = $puppet::params::r10k_package_name,
    Stdlib::Absolutepath
            $gem_path            = $puppet::params::gem_path,
    Stdlib::Absolutepath
            $r10k_path           = $puppet::params::r10k_path,
) inherits puppet::params
{
    include puppet::agent::install

    exec { "${gem_path} install ${r10k_package_name}":
        creates => $r10k_path,
        require => Package['puppet-agent'],
        alias   => 'r10k-installation',
    }
}
