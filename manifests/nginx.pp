# @summary Front Puppet Server with an nginx TLS-terminating proxy
#
# Puts nginx in front of Puppet Server so that client-certificate policy can be
# decided per request path, which a single Jetty listener cannot do.
#
# The problem this solves: certificate enrolment is inherently certificate-less -
# a node contacts the CA precisely because it has none yet. Puppet Server applies
# one `client-auth` value to every path it serves, so requiring a certificate for
# catalogues also blocks enrolment, and allowing enrolment leaves catalogues open
# to certificate-less callers. Terminating TLS in nginx allows `/puppet-ca` to
# accept a certificate-less client while every other path rejects one.
#
# Agents are unaffected: nginx answers on the port they already use, presenting
# the same Puppet Server certificate.
#
# ⚠ **This moves authorisation into the proxy.** Puppet Server can no longer see
# the client certificate, so identity arrives as `X-Client-*` request headers and
# Puppet Server must be configured to trust them (`allow-header-cert-info`). Two
# things follow, and neither is optional:
#
#   1. Puppet Server must listen on loopback only. Anything able to reach it
#      directly can forge those headers and impersonate any node, including the
#      CLI-auth extension. See `puppet::config::webserver::tls_offload`.
#   2. Every location must overwrite the headers, including the CA one. A path
#      that forwards a client-supplied `X-Client-DN` lets an unauthenticated
#      caller claim to be anyone. That is why they are set here rather than left
#      to per-site configuration.
#
# @param manage_nginx_core
#   Whether to manage nginx core settings - installation, nginx.conf, service.
#   Set to false where nginx core is already owned by something else on the host,
#   in which case only the server and locations below are declared.
#
#   ⚠ With this false, `class nginx` must still be declared somewhere in the
#   catalogue: the resource types used below read `$nginx::spdy` and other core
#   variables, and the catalogue fails without them. This class deliberately does
#   not `include nginx` itself - declaring it before whatever owns core would be a
#   duplicate declaration, and evaluation order between the two is not something
#   to rely on.
#
# @param listen_ip
#   Address nginx serves on. It should be the address agents resolve for this
#   server, never a wildcard - binding every interface is how a management
#   endpoint ends up on a public one.
#
#   Must be RFC 1918 private space: `10.0.0.0/8`, `172.16.0.0/12` or
#   `192.168.0.0/16`. Note the middle one is `172.16.` to `172.31.` only -
#   `172.0.` to `172.15.` and `172.32.` upwards are public, so a bare `172.`
#   check would let real internet addresses through.
#
#   Left undefined, the first private address on the host is used, in interface
#   order. Loopback is excluded automatically, being outside RFC 1918. If the
#   host has no private address the catalogue fails rather than guessing.
#
# @param use_external_ip
#   Waive the private-address requirement, for a deployment that genuinely needs
#   to serve on public space. Off by default: the failure it prevents is exposing
#   a Puppet Server to the internet, which is not something to discover later.
#
# @param listen_port
#   Port nginx serves on. Defaults to 8140, the port agents already use.
#
# @param proxy_host
#   Address of the Puppet Server listener to forward to. Loopback by design.
#
# @param proxy_port
#   Port of the Puppet Server listener to forward to. Defaults to 8140 - the same
#   number nginx serves publicly, which is safe because the addresses differ, and
#   useful because an nginx that accidentally binds all interfaces then collides
#   with Puppet Server and refuses to start rather than listening in the wrong
#   place.
#
# @param ca_location
#   Request path served without requiring a client certificate.
#
# @param ssl_cert
#   Server certificate presented to agents. Puppet Server's own host certificate,
#   so agents see no change.
#
# @param ssl_key
#   Private key for the above.
#
# @param ssl_ca_cert
#   CA certificate used to verify client certificates.
#
# @param ssl_crl_path
#   Certificate revocation list. Without it a revoked certificate still
#   authenticates, because nginx has taken over verification from Puppet Server.
#
# @example
#   include puppet::nginx
#
class puppet::nginx (
  Boolean $manage_nginx_core = true,
  Optional[Stdlib::IP::Address::V4::Nosubnet] $listen_ip = undef,
  Boolean $use_external_ip = false,
  Stdlib::Port $listen_port = 8140,
  Stdlib::IP::Address $proxy_host = '127.0.0.1',
  Stdlib::Port $proxy_port = 8140,
  String $ca_location = '/puppet-ca',
  Stdlib::Absolutepath $ssl_cert = $puppet::globals::hostcert,
  Stdlib::Absolutepath $ssl_key = $puppet::globals::hostprivkey,
  Stdlib::Absolutepath $ssl_ca_cert = $puppet::globals::localcacert,
  Stdlib::Absolutepath $ssl_crl_path = $puppet::globals::hostcrl,
) inherits puppet::globals {
  # Address selection is deliberately strict: this listener is the fleet's control
  # plane, and the failure it guards against - publishing it on a public address -
  # is not one you want to discover from outside.
  #
  # Range membership comes from bsys::is_private_ip, which compares with IPAddr
  # rather than string prefixes. That matters for 172.16.0.0/12: a '172.' prefix
  # check also accepts 172.0-172.15 and 172.32-172.255, which are public.
  if $listen_ip {
    $address = $listen_ip

    unless $use_external_ip or bsys::is_private_ip(String($address)) {
      fail("puppet::nginx: listen_ip ${address} is outside RFC 1918 private space (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16). This would expose Puppet Server on a public address. Set use_external_ip => true only if that is genuinely intended.")
    }
  }
  elsif $puppet::globals::internal_ip {
    # Shared with puppet::config::webserver through puppet::globals, so both
    # answer the question "what is this server reachable on" the same way.
    $address = $puppet::globals::internal_ip
  }
  elsif $use_external_ip {
    $address = $facts['networking']['ip']
  }
  else {
    fail('puppet::nginx: no RFC 1918 private address found on this host, and listen_ip was not given. Refusing to guess - a wrong choice here publishes Puppet Server on whatever address it lands on. Set listen_ip explicitly, or use_external_ip => true if this host really has no private address.')
  }

  if $manage_nginx_core {
    include lsys_nginx
  }

  $proxy_url = "http://${proxy_host}:${proxy_port}"

  # Set on EVERY location, never conditionally. proxy_set_header replaces any
  # header of the same name arriving from the client, so declaring all three
  # everywhere is what stops a caller supplying its own identity. A location that
  # omits them is an authentication bypass, not a missing optimisation.
  $client_cert_headers = [
    'X-Client-Verify $ssl_client_verify',
    'X-Client-DN $ssl_client_s_dn',
    'X-Client-Cert $ssl_client_escaped_cert',
    'Host $host',
    'X-Real-IP $remote_addr',
    'X-Forwarded-For $proxy_add_x_forwarded_for',
  ]

  # `optional` rather than `on`: the CA path has to accept a client with no
  # certificate at all. Requests that do present one are still verified against
  # the CA and the CRL, and the per-location check below turns that verification
  # into policy for everything except the CA.
  nginx::resource::server { 'puppetserver':
    listen_ip            => $address,
    listen_port          => $listen_port,
    ssl                  => true,
    ssl_port             => $listen_port,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    ssl_client_cert      => $ssl_ca_cert,
    ssl_crl              => $ssl_crl_path,
    ssl_verify_client    => 'optional',
    use_default_location => false,
    server_name          => [$trusted['certname']],
  }

  # Catalogues, reports, file serving, the admin and status APIs: a verified
  # client certificate is required. This is the equivalent of Jetty's
  # `client-auth: need`, applied to everything except the CA.
  nginx::resource::location { 'puppetserver-default':
    server           => 'puppetserver',
    location         => '/',
    ssl              => true,
    ssl_only         => true,
    proxy            => $proxy_url,
    proxy_set_header => $client_cert_headers,
    raw_prepend      => [
      'if ($ssl_client_verify != SUCCESS) { return 403; }',
    ],
  }

  # The CA, deliberately reachable without a client certificate so that a node
  # with no certificate can request one. Authorisation for the paths underneath
  # remains Puppet Server's auth.conf, which is why the headers above matter here
  # more than anywhere else.
  nginx::resource::location { 'puppetserver-ca':
    server           => 'puppetserver',
    location         => $ca_location,
    ssl              => true,
    ssl_only         => true,
    proxy            => $proxy_url,
    proxy_set_header => $client_cert_headers,
  }
}
