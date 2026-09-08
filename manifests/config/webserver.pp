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
# @param tls_offload
#   Render a plain HTTP listener instead of an SSL one, for deployments where a
#   proxy in front of Puppet Server terminates TLS and performs client
#   certificate verification.
#
#   ⚠ This hands authorisation to the proxy. Puppet Server can no longer see the
#   client certificate, so it must be told to read the identity from request
#   headers (`allow-header-cert-info`), and anything able to reach this listener
#   directly can then forge that identity. Only enable it together with a proxy
#   on the same host and a loopback `host`, and only where the proxy overwrites
#   the `X-Client-*` headers on every location it serves.
#
#   When enabled, `client_auth`, `ssl_host`, `ssl_port` and the certificate paths
#   are not rendered: the proxy owns all of it.
#
# @param host
#   Address for the plain HTTP listener used with `tls_offload`. Defaults to
#   `127.0.0.1`, which is the security control - do not widen it.
#
# @param port
#   Port for the plain HTTP listener used with `tls_offload`. Defaults to `8140`,
#   deliberately the same port the proxy serves publicly: a proxy that
#   accidentally binds all interfaces then fails to start instead of silently
#   listening in the wrong place.
#
# @param ssl_host
#   Address Puppet Server binds to. Defaults to this host's first private
#   address.
#
#   ⚠ There is deliberately no wildcard default. Binding `0.0.0.0` puts the
#   fleet's control plane on every interface the host happens to have, including
#   ones added later, which is how a management service ends up facing a network
#   nobody intended. Name the address instead.
#
#   Set `127.0.0.1` to make Puppet Server unreachable except through a proxy on
#   the same host - see `puppet::nginx`. Only do that together with such a proxy:
#   on its own it removes the server from the network and every agent fails to
#   fetch a catalogue.
#
#   The catalogue fails if this is unset and the host has no private address,
#   rather than falling back to a wildcard.
#
# @param ssl_port
#   Port Puppet Server binds to. Defaults to `8140`. Change it only when
#   something else is answering on 8140 for the agents, such as a proxy that
#   forwards to this port.
#
# @example
#   include puppet::config::webserver
class puppet::config::webserver (
  Enum['need', 'want', 'none'] $client_auth = 'want',
  Optional[Stdlib::IP::Address] $ssl_host = $puppet::globals::internal_ip,
  Stdlib::Port $ssl_port = 8140,
  Boolean $tls_offload = false,
  Stdlib::IP::Address $host = '127.0.0.1',
  Stdlib::Port $port = 8140,
  Stdlib::Absolutepath $ssl_cert = $puppet::globals::hostcert,
  Stdlib::Absolutepath $ssl_key = $puppet::globals::hostprivkey,
  Stdlib::Absolutepath $ssl_ca_cert = $puppet::globals::localcacert,
  Stdlib::Absolutepath $ssl_cert_chain = $puppet::globals::localcacert,
  Stdlib::Absolutepath $ssl_crl_path = $puppet::globals::hostcrl,
) inherits puppet::globals {
  include puppet::server::install

  unless $tls_offload or $ssl_host {
    fail('puppet::config::webserver: no ssl_host given and this host has no private address to default to. Set ssl_host explicitly. Do not use 0.0.0.0 - binding every interface exposes the fleet control plane on any network this host is later attached to.')
  }

  $config = $puppet::globals::config
  $server_confdir = $puppet::globals::server_confdir

  # https://www.puppet.com/docs/puppet/7/server/config_file_webserver.html
  # https://github.com/puppetlabs/trapperkeeper-webserver-jetty9/blob/main/doc/jetty-config.md
  file { "${config}/webserver.conf":
    ensure  => file,
    content => template('puppet/webserver.conf.erb'),
    require => Class['puppet::server::install'],
  }
}
