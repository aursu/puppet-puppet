# puppet::params
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet::params
class puppet::params {
    $platform_name       = 'puppet5'
    $os_version          = $operatingsystemmajrelease
    case $::osfamily {
        'RedHat': {
            case $::operatingsystem {
                'Fedora': {
                    $os_abbreviation = 'fedora'
                }
                default: {
                    $os_abbreviation = 'el'
                }
            }
            $repo_urlbase = 'https://yum.puppet.com/puppet5'
            $version_codename = "${os_abbreviation}-${os_version}"
            $package_provider = 'rpm'
        }
        'Suse': {
            $repo_urlbase = 'https://yum.puppet.com/puppet5'
            $os_abbreviation  = 'sles'
            $version_codename = "${os_abbreviation}-${os_version}"
            $package_provider = 'rpm'
        }
        'Debian': {
            $repo_urlbase = 'https://apt.puppetlabs.com'
            $version_codename = $::lsbdistcodename
            $package_provider = 'dpkg'
        }
    }
    $package_name        = "${platform_name}-release"
    $package_filename    = "${package_name}-${version_codename}.noarch.rpm"
    $platform_repository = "${repo_urlbase}/${package_filename}"
    $agent_package_name  = 'puppet-agent'
    $server_package_name = 'puppetserver'
    $r10k_package_name   = 'r10k'
    $gem_path            = '/opt/puppetlabs/puppet/bin/gem'
    $r10k_path           = '/opt/puppetlabs/puppet/bin/r10k'
    $service_name        = 'puppetserver'
}
