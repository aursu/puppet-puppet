# @summary Puppet bootstrap commands
#
# Puppet bootstrap commands
#
# @example
#   include puppet::agent::bootstrap
#
# @param puppet_path
# @param options
# @param hostprivkey
# @param hostcert
# @param certname
#
class puppet::agent::bootstrap (
  Stdlib::Unixpath $puppet_path = $puppet::params::puppet_path,
  String $options = '--test',
  Stdlib::Unixpath $hostprivkey = $puppet::params::hostprivkey,
  Stdlib::Unixpath $hostcert = $puppet::params::hostcert,
  Optional[String] $certname = undef,
) inherits puppet::params {
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

  # copy certname PEM file to clientcert PEM file
  if $certname {
    exec {
      default:
        path   => '/bin:/usr/bin',
        onlyif => "test -f ${certname}.pem";
      "cp -a ${certname}.pem ${hostcert}":
        cwd     => $puppet::params::certdir,
        creates => $hostcert,
        require => Exec['puppet-bootstrap-cert'];
      "cp -a ${certname}.pem ${hostprivkey}":
        cwd     => $puppet::params::privatekeydir,
        creates => $hostprivkey,
        require => Exec['puppet-bootstrap-privkey'];
    }
  }
}
