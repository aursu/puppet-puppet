# @summary r10k dependencies
#
# r10k dependencies (GEM packages with specific requirements)
#
# @example
#   include puppet::r10k::dependencies
class puppet::r10k::dependencies {
  include puppet::agent::install

  if versioncmp($facts['puppetversion'], '8.0.0') >= 0 {
    $cri_ensure = 'installed'
  }
  elsif versioncmp($facts['puppetversion'], '7.0.0') >= 0 {
    $cri_ensure = 'installed'

    # https://www.puppet.com/docs/puppet/8/platform_lifecycle.html#about_agent-component-version-numbers
    # Puppet 7 provides Ruby 2.7.8
    # The following GEM packages already require Ruby 3, so we need to install specific versions compatible with Puppet 7

    package { 'faraday-net_http':
      ensure   => '3.0.2',
      provider => 'puppet_gem',
    }

    package { 'faraday':
      ensure   => '2.8.1',
      provider => 'puppet_gem',
    }

    Class['puppet::agent::install'] -> Package['faraday']
    Class['puppet::agent::install'] -> Package['faraday-net_http']
  }
  elsif versioncmp($facts['puppetversion'], '6.0.0') >= 0 {
    # Puppet 6 comes with Ruby >= 2.5
    $cri_ensure = 'installed'
  }
  else {
    # Puppet 5
    # cri-2.15.10 requires Ruby ~> 2.3
    $cri_ensure = '2.15.10'
  }

  package { 'cri':
    ensure   => $cri_ensure,
    provider => 'puppet_gem',
  }

  Class['puppet::agent::install'] -> Package['cri']
}
