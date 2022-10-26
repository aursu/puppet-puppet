# puppet::config
#
# Setup Puppet configuration file (puppet.conf)
#
# @param puppet_server
#   Flag - if set to true then host will be set up as Puppet server
#
# @param server
# @param ca_server
#
# @param basemodulepath
#   The search path for global modules. Should be specified as a list of
#   directories separated by the system path separator character. (The POSIX
#   path separator is ':', and the Windows path separator is ';'.)
#   These are the modules that will be used by all environments. Note that the
#   modules directory of the active environment will have priority over any global
#   directories. For more info,
#   see https://docs.puppet.com/puppet/latest/environments.html
#   Default: $codedir/modules:/opt/puppetlabs/puppet/modules
#
# @param common_envname
#   String. Default is 'common'. Name of common environment which will consists
#   global Hiera config (data/global.yaml) and glomal modules (see use_common_env
#   and basemodulepath)
#
# @param use_common_env
#   If set to true then basemodulepath will set to
#   "${environmentpath}/${common_envname}/modules" only if basemodulepath parameter
#   (see above) is not defined.
#
# @param dns_alt_names
#   Array of String or undef. A comma-separated list of alternate DNS names for
#   Puppet Server. These are extra hostnames (in addition to its certname) that
#   the server is allowed to use when serving agents. Puppet checks this setting
#   when automatically requesting a certificate for Puppet agent or Puppet Server,
#   and when manually generating a certificate with puppet cert generate.
#   In order to handle agent requests at a given hostname (like
#   "puppet.example.com"), Puppet Server needs a certificate that proves it’s
#   allowed to use that name; if a server shows a certificate that doesn’t include
#   its hostname, Puppet agents will refuse to trust it. If you use a single
#   hostname for Puppet traffic but load-balance it to multiple Puppet Servers,
#   each of those servers needs to include the official hostname in its list of
#   extra names.
#   Note: The list of alternate names is locked in when the server’s certificate
#   is signed. If you need to change the list later, you can’t just change this
#   setting; you also need to:
#     * On the server: Stop Puppet Server.
#     * On the CA server: Revoke and clean the server’s old certificate. (puppet
#       cert clean <NAME>)
#     * On the server: Delete the old certificate (and any old certificate signing
#       requests) from the ssldir.
#     * On the server: Run puppet agent -t --ca_server <CA HOSTNAME> to request a
#       new certificate
#     * On the CA server: Sign the certificate request, explicitly allowing
#       alternate names (puppet cert sign --allow-dns-alt-names <NAME>).
#     * On the server: Run puppet agent -t --ca_server <CA HOSTNAME> to retrieve
#       the cert.
#     * On the server: Start Puppet Server again.
#   To see all the alternate names your servers are using, log into your CA server
#   and run puppet cert list -a, then check the output for (alt names: ...). Most
#   agent nodes should NOT have alternate names; the only certs that should have
#   them are Puppet Server nodes that you want other agents to trust.
#
# @param environment_timeout
#   Puppet::TimeUnit. Default - 0. How long the Puppet server should cache data it
#   loads from an environment. This setting can be a time interval in seconds (30
#   or 30s), minutes (30m), hours (6h), days (2d), or years (5y). A value of 0
#   will disable caching. This setting can also be set to unlimited, which will
#   cache environments until the server is restarted or told to refresh the cache.
#   You should change this setting once your Puppet deployment is doing non-
#   trivial work. We chose the default value of 0 because it lets new users update
#   their code without any extra steps, but it lowers the performance of your
#   Puppet server.
#   We recommend setting this to unlimited and explicitly refreshing your Puppet
#   server as part of your code deployment process.
#     * With Puppet Server, you should refresh environments by calling the
#       environment-cache API endpoint. See the docs for the Puppet Server
#       administrative API.
#     * With a Rack Puppet server, you should restart the web server or the
#       application server. Passenger lets you touch a restart.txt file to refresh
#       an application without restarting Apache; see the Passenger docs for
#       details.
#   We don’t recommend using any value other than 0 or unlimited, since most
#   Puppet servers use a pool of Ruby interpreters which all have their own cache
#   timers. When these timers drift out of sync, agents can be served inconsistent
#   catalogs.
#   Default: 0
#
# @param sameca
#   Whether the server should function as a certificate
#   authority.
#   Default: true
#
# @param allow_duplicate_certs
#   Whether to allow a new certificate request to
#   overwrite an existing certificate.
#   Default: false
#
# @param use_enc
#   When enabled, Puppet will use external nodes
#   classifier script which defined in puppet::params::external_nodes variable
#
# @summary Setup Puppet configuration file (puppet.conf)
#
# @example
#   include puppet::config
class puppet::config (
  Boolean $puppet_server = $puppet::master,
  String $server = $puppet::server,
  Optional[String] $ca_server = $puppet::ca_server,
  Boolean $use_common_env = $puppet::use_common_env,
  String $common_envname = $puppet::common_envname,
  Optional[Stdlib::Absolutepath] $basemodulepath = $puppet::basemodulepath,
  Optional[Array[String]] $dns_alt_names = $puppet::dns_alt_names,
  Puppet::Strictness $strict = $puppet::strict,
  Boolean $strict_variables = $puppet::strict_variables,
  Boolean $daemonize = $puppet::daemonize,
  Boolean $onetime = $puppet::onetime,
  Puppet::TimeUnit $http_read_timeout = $puppet::http_read_timeout,
  Puppet::Ordering $ordering = $puppet::ordering,
  Optional[Puppet::Priority] $priority = $puppet::priority,
  Boolean $usecacheonfailure = $puppet::usecacheonfailure,
  Puppet::TimeUnit $environment_timeout = $puppet::environment_timeout,
  Boolean $sameca = $puppet::sameca,
  Optional[Puppet::Autosign] $autosign = $puppet::autosign,
  Boolean $allow_duplicate_certs = $puppet::allow_duplicate_certs,
  Boolean $use_enc = $puppet::use_enc,
  Boolean $use_puppetdb = $puppet::use_puppetdb,
  # predefined via params
  Stdlib::Absolutepath $puppet_config = $puppet::params::puppet_config,
  Stdlib::Absolutepath $environmentpath = $puppet::params::environmentpath,
  Stdlib::Absolutepath $external_nodes = $puppet::params::external_nodes,
  Optional[String] $node_environment = undef,
  Optional[Puppet::TimeUnit] $runtimeout = $puppet::runtimeout,
) inherits puppet::params {
  include puppet::agent::install
  include puppet::globals

  $platform_name = $puppet::globals::platform_name

  if $platform_name == 'puppet5' {
    $server_section = 'master'
    $server_sameca  = $sameca
  }
  else {
    $server_section = 'server'
    # we do not want to have 'ca' directive in puppet.conf for Puppet 6+
    $server_sameca  = true
  }

  file { 'puppet-config':
    path    => $puppet_config,
    content => template('puppet/puppet.conf.erb'),
  }

  if $puppet_server {
    class { 'puppet::server::ca::allow':
      server    => $server,
      ca_server => $ca_server,
    }

    # https://puppet.com/docs/puppet/7.5/server/configuration.html#service-bootstrapping
    file { '/etc/puppetlabs/puppetserver/services.d/ca.cfg':
      ensure  => file,
      content => template('puppet/services.ca.cfg.erb'),
    }
  }

  Class['puppet::agent::install'] -> File['puppet-config']
}
