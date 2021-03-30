# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::profile::agent
class puppet::profile::agent (
    Puppet::Platform
            $platform_name = 'puppet7',
    String  $server        = 'puppet',
) {
    class { 'puppet':
      server => $server,
    }

    class { 'puppet::globals':
      platform_name => $platform_name,
    }

    class { 'puppet::agent::install': }

    class { 'puppet::agent::config':
      server           => $server,
      node_environment => $::environment,
    }

    class { 'puppet::setup': }
}
