# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::puppetdb::globals
class puppet::puppetdb::globals (
  Boolean $puppet_platform_distro = $puppet::globals::puppet_platform_distro,
) inherits puppet::globals {
  include puppetdb::params

  if $puppet_platform_distro {
    $confdir = $puppetdb::params::confdir
    $ssl_dir = $puppetdb::params::ssl_dir
    $vardir  = $puppetdb::params::vardir
  }
  else {
    $confdir = '/etc/puppetdb/conf.d'
    $ssl_dir = '/etc/puppetdb/ssl'
    $vardir  = '/var/lib/puppetdb'
  }
}
