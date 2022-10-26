# @summary Creating and configuring Puppet Server compilers
#
# Creating and configuring Puppet Server compilers
# https://puppet.com/docs/puppet/7/server/scaling_puppet_server.html
#
# @example
#   include puppet::profile::compiler
class puppet::profile::compiler (
    Stdlib::Host
            $ca_server,
    Puppet::Platform
            $platform_name              = 'puppet7',
    Stdlib::Host
            $server                     = $ca_server,

    Boolean $use_common_env             = false,
    Optional[String]
            $common_envname             = undef,

    Boolean $use_puppetdb               = true,
    Stdlib::Host
            $puppetdb_server            = 'puppet',
)
{
  class { 'puppet::profile::server':
    sameca          => false,
    puppetdb_local  => false,
    postgres_local  => false,

    platform_name   => $platform_name,

    server          => $server,
    use_puppetdb    => $use_puppetdb,
    puppetdb_server => $puppetdb_server,

    hosts_update    => false,

    use_common_env  => $use_common_env,
    common_envname  => $common_envname,

    ca_server       => $ca_server,
  }
  contain puppet::profile::server
}
