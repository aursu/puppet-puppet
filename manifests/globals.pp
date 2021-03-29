# @summary Module global settings
#
# Module global settings
#
# @example
#   include puppet::globals
class puppet::globals (
  Puppet::Platform
          $platform_name = 'puppet7',
) inherits puppet::params
{
  $package_name     = "${platform_name}-release"
  $version_codename = $puppet::params::version_codename

  case $::osfamily {
    'Suse': {
      $repo_urlbase = "https://yum.puppet.com/${platform_name}"
      $package_filename = "${package_name}-${version_codename}.noarch.rpm"
    }
    'Debian': {
      $repo_urlbase = 'https://apt.puppetlabs.com'
      $package_filename = "${package_name}-${version_codename}.deb"
    }
    # default is RedHat based systems
    default: {
      $repo_urlbase = "https://yum.puppet.com/${platform_name}"
      $package_filename = "${package_name}-${version_codename}.noarch.rpm"
    }
  }

  $platform_repository = "${repo_urlbase}/${package_filename}"
}
