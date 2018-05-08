# puppet::repo
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::repo
class puppet::repo (
    String $package_name        = $puppet::params::package_name,
    String $package_filename    = $puppet::params::package_filename,
    String $package_provider    = $puppet::params::package_provider,
    String $platform_repository = $puppet::params::platform_repository,
) inherits puppet::params
{
    exec { "curl ${platform_repository} -s -o ${package_filename}":
        cwd     => '/tmp',
        path    => '/bin:/usr/bin',
        creates => "/tmp/${package_filename}",
        alias   => 'download-release-package',
    }
    package { $package_name:
        provider => $package_provider,
        source   => "/tmp/${package_filename}",
        require  => Exec['download-release-package'],
        alias    => 'puppet5-repository',
    }
}
