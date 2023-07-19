# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @param dns_alt_names
#   Subject alternative names for the generated cert
#
# @param certname
#   --certname parameter for generate command or not. If set to true
#   than $::fqdn will be used as certname.
#
# @example
#   include puppet::server::ca::generate
class puppet::server::ca::generate (
  Array[Stdlib::Fqdn] $dns_alt_names = ['puppet', $facts['networking']['fqdn']],
  Variant[Boolean, Stdlib::Fqdn] $certname = true,
  Variant[Pattern[/^[0-9]+[smhdy]?/], Integer] $ttl = '10y',
) {
  include puppet::globals

  $subject_alt_names_param = $dns_alt_names[0] ? {
    Stdlib::Fqdn => join(['--subject-alt-names', join($dns_alt_names, ',')], ' '),
    default      => '',
  }

  $certname_param = $certname ? {
    Stdlib::Fqdn => "--certname ${certname}",
    true         => "--certname ${facts['networking']['fqdn']}",
    default      => '',
  }

  $cert_generate_files = $puppet::globals::cert_generate_files
  $hostcert = $puppet::globals::hostcert

  # These Certificate assets shold be cleaned up before generate
  $timestamp = Timestamp.new().strftime('%Y%m%dT%H%M%S')
  $cert_generate_files.each |Stdlib::Unixpath $path| {
    exec { "backup ${path}":
      path    => '/bin:/usr/bin',
      command => "mv -n ${path} ${path}.${timestamp}",
      onlyif  => "test -f ${path}",
      unless  => "openssl x509 -in ${hostcert} -checkend 0",
      before  => Exec['puppetserver ca generate'],
    }
  }

  exec { 'stop puppetserver':
    command => 'systemctl stop puppetserver',
    path    => '/bin:/usr/bin',
    onlyif  => 'systemctl status puppetserver',
    unless  => "openssl x509 -in ${hostcert} -checkend 0",
  }

  #  puppetserver ca generate --force --certname ci1-lv-lw-eu.host.gface.com --subject-alt-names ci1-lv-lw-eu.host.gface.com,puppet --ttl 10y --ca-client
  exec { 'puppetserver ca generate':
    path    => '/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/bin:/usr/bin',
    command => "puppetserver ca generate --force --ca-client ${certname_param} ${subject_alt_names_param} --ttl ${ttl}", # lint:ignore:140chars
    unless  => "openssl x509 -in ${hostcert} -checkend 0",
    require => Exec['stop puppetserver'],
  }
}
