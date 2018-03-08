# puppet::repo
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::repo
class puppet::repo (
    $package_name        = $puppet5::params::package_name,
    $package_filename    = $puppet5::params::package_filename,
    $package_provider    = $puppet5::params::package_provider,
    $platform_repository = $puppet5::params::platform_repository,
) inherits puppet::params
{
    exec { 'download-release--package':
        command => "curl ${platform_repository} -s -o ${package_filename}",
        cwd     => '/tmp',
        path    => '/bin:/usr/bin',
        creates => "/tmp/${package_filename}",
    }
    package { 'puppet5-repository':
        name     => $package_name,
        provider => $package_provider,
        source   => "/tmp/${package_filename}",
        require  => Exec['download-release-package']
    }
}

