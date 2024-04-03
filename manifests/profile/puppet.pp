# @summary Puppet installation
#
# Puppet installation
#
# @param platform_name
#   Puppet platform name. Either puppet5, puppet6, puppet7 or puppet8
#
# @param puppetserver
#   Whether it is Puppet server or not
#
# @param sameca
#   Whether Puppet server provides CA service or not
#   If not - it is compiler Puppet server
#   see https://puppet.com/docs/puppet/7/server/scaling_puppet_server.html
#   If server is compiler then
#     - no Puppet CA and
#     - no PuppetDB on it
#
# @param use_puppetdb
#   Whether to use PuppetDB for this Puppet server or not
#
# @param puppetdb_local
#   Whether to install PuppetDB on same server or not
#
# @param postgres_local
#   Whether to manage PostgreSQL server installation on same server or not
#   It has no effect if puppetdb_local is false
#
# @param manage_database
#   Whether to manage Postgres database resources for PuppetDB on same server or not
#
# @param server
#   Puppet server name
#
# @param puppetdb_server
#   PuppetDB server name if external
#
# @param ca_server
#
# @param hosts_update
#   Whether to setup puppet server hostnamr into /etc/hosts file
#
# @param use_common_env
# @param common_envname
#
# @param enc_envname
#   Default ENC environment repo is 'enc'
#   This parameter is to define different name for it
#
# @param r10k_crontab_setup
#   Whether to setup crontab job to sync Puppet code
#
# @param manage_webserver_conf
#   Whether to manage webserver.conf or not
#
# @example
#   include puppet::profile::puppet
class puppet::profile::puppet (
  Puppet::Platform $platform_name = 'puppet8',
  Boolean $puppetserver = false,
  Boolean $sameca = false,
  Boolean $use_puppetdb = true,
  Boolean $puppetdb_local = true,
  Boolean $postgres_local = true,
  Boolean $manage_database = $postgres_local,
  Stdlib::Host $server = 'puppet',
  Stdlib::Host $puppetdb_server = 'puppet',
  # https://puppet.com/docs/puppet/7/server/scaling_puppet_server.html#directing-individual-agents-to-a-central-ca
  Optional[Stdlib::Host] $ca_server = undef,
  Boolean $hosts_update = false,
  Boolean $use_common_env = false,
  Optional[String] $common_envname = undef,
  Optional[String] $enc_envname = undef,
  Boolean $r10k_crontab_setup = false,
  Boolean $manage_webserver_conf = false,
  Boolean $manage_fileserver_config = true,
  Hash[String, Stdlib::Absolutepath] $mount_points = {},
) {
  if $puppetserver {
    if $sameca {
      class { 'puppet::profile::server':
        platform_name            => $platform_name,
        ca_server                => $ca_server,
        server                   => $server,
        sameca                   => $sameca,
        hosts_update             => $hosts_update,
        use_puppetdb             => $use_puppetdb,
        puppetdb_server          => $puppetdb_server,
        puppetdb_local           => $puppetdb_local,
        manage_database          => $manage_database,
        use_common_env           => $use_common_env,
        common_envname           => $common_envname,
        enc_envname              => $enc_envname,
        r10k_crontab_setup       => $r10k_crontab_setup,
        manage_webserver_conf    => $manage_webserver_conf,
        manage_fileserver_config => $manage_fileserver_config,
        mount_points             => $mount_points,
      }
      contain puppet::profile::server
    }
    else {
      class { 'puppet::profile::compiler':
        platform_name            => $platform_name,
        ca_server                => $ca_server,
        server                   => $server,
        use_common_env           => $use_common_env,
        common_envname           => $common_envname,
        use_puppetdb             => $use_puppetdb,
        puppetdb_server          => $puppetdb_server,
        puppetdb_local           => $puppetdb_local,
        manage_database          => $manage_database,
        enc_envname              => $enc_envname,
        r10k_crontab_setup       => $r10k_crontab_setup,
        manage_webserver_conf    => $manage_webserver_conf,
        manage_fileserver_config => $manage_fileserver_config,
        mount_points             => $mount_points,
      }
      contain puppet::profile::compiler
    }
  }
  else {
    class { 'puppet::profile::agent':
      platform_name => $platform_name,
      server        => $server,
      ca_server     => $ca_server,
    }
  }
}
