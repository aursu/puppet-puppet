# @summary TLS setup for PuppetDB web service
#
# Copies Puppet agent's certificate PEM file, private key PEM file, and CA certificate PEM file
# to the PuppetDB web service SSL directory for HTTPS.
#
# @example
#   include puppet::puppetdb::https_config
class puppet::puppetdb::https_config {
  include puppet::params
  include puppetdb::params

  $localcacert = assert_type(Stdlib::Unixpath, $puppet::params::localcacert)
  $hostcert    = assert_type(Stdlib::Unixpath, $puppet::params::hostcert)
  $hostprivkey = assert_type(Stdlib::Unixpath, $puppet::params::hostprivkey)

  $puppetdb_group   = assert_type(String, $puppetdb::params::puppetdb_group)
  $puppetdb_service = assert_type(String, $puppetdb::params::puppetdb_service)

  $ssl_dir          = assert_type(Stdlib::Unixpath, $puppetdb::params::ssl_dir)
  $ssl_key_path     = assert_type(Stdlib::Unixpath, $puppetdb::params::ssl_key_path)
  $ssl_cert_path    = assert_type(Stdlib::Unixpath, $puppetdb::params::ssl_cert_path)
  $ssl_ca_cert_path = assert_type(Stdlib::Unixpath, $puppetdb::params::ssl_ca_cert_path)

  file {
    $ssl_dir:
      ensure => directory,
      owner  => 'root',
      group  => $puppetdb_group,
      mode   => '0750';
    $ssl_key_path:
      ensure => file,
      owner  => 'root',
      group  => $puppetdb_group,
      mode   => '0640',
      source => $hostprivkey,
      notify => Service[$puppetdb_service];
    $ssl_cert_path:
      ensure  => file,
      owner   => 'root',
      group   => $puppetdb_group,
      mode    => '0640',
      source  => $hostcert,
      notify  => Service[$puppetdb_service];
    $ssl_ca_cert_path:
      ensure  => file,
      owner   => 'root',
      group   => $puppetdb_group,
      mode    => '0640',
      source  => $localcacert,
      notify  => Service[$puppetdb_service];
  }
}
