# @summary PuppetDB global settings
#
# This class provides global settings for PuppetDB installation
#
# @param puppet_platform_distro
#   Whether to use Puppet Platform distribution packages
#
# @example
#   include puppet::puppetdb::globals
class puppet::puppetdb::globals (
  Boolean $puppet_platform_distro = $puppet::globals::puppet_platform_distro,
) inherits puppet::globals {
  include puppetdb::params

  $is_openvox = $puppet::globals::is_openvox

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

  if $is_openvox {
    $puppetdb_package    = 'openvoxdb'
    $terminus_package    = 'openvoxdb-termini'
  }
  else {
    $puppetdb_package    = $puppetdb::params::puppetdb_package
    $terminus_package    = $puppetdb::params::terminus_package
  }
}
