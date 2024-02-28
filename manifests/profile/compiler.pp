# @summary Creating and configuring Puppet Server compilers
#
# Creating and configuring Puppet Server compilers
# https://puppet.com/docs/puppet/7/server/scaling_puppet_server.html
#
# @example
#   include puppet::profile::compiler
#
# @param ca_server
# @param platform_name
# @param server
# @param use_common_env
# @param common_envname
# @param use_puppetdb
# @param puppetdb_server
#
# @param enc_envname
#   The name of ENC environment inside Puppet environments path.
#   Use it to override default value 'enc'
#
# @param r10k_crontab_setup
#   Whether to setup crontab job to sync Puppet code for Puppet compiler
#
# @param manage_webserver_conf
#   Whether to manage webserver.conf or not
#
class puppet::profile::compiler (
  Stdlib::Host $ca_server,
  Puppet::Platform $platform_name = 'puppet8',
  Stdlib::Host $server = $ca_server,
  Boolean $use_common_env = false,
  Optional[String] $common_envname = undef,
  Boolean $use_puppetdb = true,
  Stdlib::Host $puppetdb_server = 'puppet',
  Optional[String] $enc_envname  = undef,
  Boolean $r10k_crontab_setup = false,
  Boolean $manage_webserver_conf = false,
  Boolean $manage_fileserver_config = true,
  Hash[String, Stdlib::Absolutepath] $mount_points = {},
) {
  class { 'puppet::profile::server':
    sameca                   => false,
    puppetdb_local           => false,
    postgres_local           => false,

    platform_name            => $platform_name,

    server                   => $server,
    use_puppetdb             => $use_puppetdb,
    puppetdb_server          => $puppetdb_server,

    hosts_update             => false,

    use_common_env           => $use_common_env,
    common_envname           => $common_envname,

    enc_envname              => $enc_envname,

    ca_server                => $ca_server,

    r10k_crontab_setup       => $r10k_crontab_setup,
    manage_webserver_conf    => $manage_webserver_conf,

    manage_fileserver_config => $manage_fileserver_config,
    mount_points             => $mount_points,
  }
  contain puppet::profile::server
}
