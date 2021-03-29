# puppet::setup
#
# Puppet node environment setup
#
# @summary Puppet node environment setup (either agent or server host)
#
# @param external_facts_setup
#   whether to setup directories for external facts
#   see https://puppet.com/docs/puppet/6.18/external_facts.html
#
# @example
#   include puppet::setup
class puppet::setup (
    String  $server_name          = $puppet::server,
    Boolean $hosts_update         = $puppet::hosts_update,
    Optional[String]
            $server_ipaddress     = $puppet::server_ipaddress,
    Optional[Array[String]]
            $dns_alt_names        = $puppet::dns_alt_names,
    Boolean $external_facts_setup = $puppet::external_facts_setup,
) inherits puppet::params
{
    if $hosts_update and $server_ipaddress {
        host { $server_name:
            ensure       => 'present',
            ip           => $server_ipaddress,
            host_aliases => $dns_alt_names,
        }
    }

    if $external_facts_setup {
        # https://puppet.com/docs/puppet/7.5/external_facts.html#executable-fact-locations
        file {
            ['/etc/facter',
            '/etc/facter/facts.d',
            '/opt/puppetlabs/facter',
            '/opt/puppetlabs/facter/facts.d',
            '/etc/puppetlabs/facter',
            '/etc/puppetlabs/facter/facts.d']:
                ensure => directory,
        }
    }
}
