# @summary webserver.conf file
#
# The webserver.conf file configures the Puppet Server webserver service
#
# @param client_auth
#   This determines the mode that the server uses to validate the client's
#   certificate for incoming SSL connections. One of the following values may
#   be specified:
#     need - The server will request the client's certificate and the
#       certificate must be provided and be valid. The certificate must have
#       been issued by a Certificate Authority whose certificate resides in the
#       truststore.
#     want - The server will request the client's certificate. A certificate,
#       if provided by the client, must have been issued by a Certificate
#       Authority whose certificate resides in the truststore. If the client
#       does not provide a certificate, the server will still consider the
#       client valid.
#     none - The server will not request a certificate from the client and will
#       consider the client valid.
#
# @param ssl_cert
#   The value of puppet server --configprint hostcert. Equivalent to the ‘SSLCertificateFile’ Apache config setting.
#
# @param ssl_key
#   The value of puppet server --configprint hostprivkey. Equivalent to the ‘SSLCertificateKeyFile’ Apache config setting.
#
# @param ssl_ca_cert
#   The value of puppet server --configprint localcacert. Equivalent to the ‘SSLCACertificateFile’ Apache config setting.
#
# @param ssl_cert_chain
#   Equivalent to the ‘SSLCertificateChainFile’ Apache config setting. 
#
# @param ssl_crl_path
#   The path to the CRL file to use.
#
# @example
#   include puppet::config::webserver
class puppet::config::webserver (
  Enum['need', 'want', 'none'] $client_auth = 'want',
  Stdlib::Absolutepath $ssl_cert = $puppet::params::hostcert,
  Stdlib::Absolutepath $ssl_key = $puppet::params::hostprivkey,
  Stdlib::Absolutepath $ssl_ca_cert = $puppet::params::localcacert,
  Stdlib::Absolutepath $ssl_cert_chain = $puppet::params::localcacert,
  Stdlib::Absolutepath $ssl_crl_path = $puppet::params::hostcrl,
) inherits puppet::params {
  # https://www.puppet.com/docs/puppet/7/server/config_file_webserver.html
  # https://github.com/puppetlabs/trapperkeeper-webserver-jetty9/blob/main/doc/jetty-config.md
  file { '/etc/puppetlabs/puppetserver/conf.d/webserver.conf':
    ensure  => file,
    content => template('puppet/webserver.conf.erb'),
  }
}
