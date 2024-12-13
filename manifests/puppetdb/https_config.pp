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
  $puppetdb_package = assert_type(String, $puppetdb::params::puppetdb_package)
  $puppetdb_service = assert_type(String, $puppetdb::params::puppetdb_service)

  $ssl_dir          = assert_type(Stdlib::Unixpath, $puppet::params::puppetdb_ssl_dir)

  # $ssl_key_path     = assert_type(Stdlib::Unixpath, $puppetdb::params::ssl_key_path)
  # $ssl_cert_path    = assert_type(Stdlib::Unixpath, $puppetdb::params::ssl_cert_path)
  # $ssl_ca_cert_path = assert_type(Stdlib::Unixpath, $puppetdb::params::ssl_ca_cert_path)

  $ssl_key_path     = "${ssl_dir}/private.pem"
  $ssl_cert_path    = "${ssl_dir}/public.pem"
  $ssl_ca_cert_path = "${ssl_dir}/ca.pem"

  file {
    default:
      ensure  => file,
      owner   => 'root',
      group   => $puppetdb_group,
      mode    => '0640',
      require => Package[$puppetdb_package],
      notify  => Service[$puppetdb_service];
    $ssl_dir:
      ensure => directory,
      mode   => '0750';
    $ssl_key_path:
      source => $hostprivkey;
    $ssl_cert_path:
      source => $hostcert;
    $ssl_ca_cert_path:
      source => $localcacert;
  }
}
