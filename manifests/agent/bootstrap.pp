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
  String $options = '--test',
  Stdlib::Unixpath $hostprivkey = $puppet::globals::hostprivkey,
  Stdlib::Unixpath $hostcert = $puppet::globals::hostcert,
  Stdlib::Unixpath $puppet_path = $puppet::globals::puppet_path,
  Optional[String] $certname = undef,
) inherits puppet::globals {
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
        cwd     => $puppet::globals::certdir,
        creates => $hostcert,
        require => Exec['puppet-bootstrap-cert'];
      "cp -a ${certname}.pem ${hostprivkey}":
        cwd     => $puppet::globals::privatekeydir,
        creates => $hostprivkey,
        require => Exec['puppet-bootstrap-privkey'];
    }
  }
}
