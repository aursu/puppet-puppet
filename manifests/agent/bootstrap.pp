# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::agent::bootstrap
class puppet::agent::bootstrap (
  Stdlib::Unixpath
          $puppet_path = $puppet::params::puppet_path,
  String  $options     = '--test',
  Stdlib::Unixpath
          $hostprivkey = $puppet::params::hostprivkey,
  Stdlib::Unixpath
          $hostcert    = $puppet::params::hostcert,
) inherits puppet::params
{
  # /opt/puppetlabs/puppet/bin/puppet agent --test
  exec {
    default:
      command => "${puppet_path} agent ${options}",
      returns => [0, 1, 2, 4, 6],
    ;
    'puppet-bootstrap-privkey':
      creates => $hostprivkey,
    ;
    'puppet-bootstrap-cert':
      creates => $hostcert,
    ;
  }
}
