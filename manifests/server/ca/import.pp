# @summary Import existing CA into current server
#
# Import existing CA into current server
#
# @param import_path
# @param dns_alt_names
#
# @param certname
#   Whether to use --certname parameter for import command or not. If set to true
#   than $::fqdn will be used as certname. If set to false - no certname parameter
#   (import command will  generate random string). If set to string - provided
#   provided string will be set as certname
#
# @example
#   include puppet::server::ca::import
class puppet::server::ca::import (
  Stdlib::Unixpath $import_path,
  Array[Stdlib::Fqdn] $dns_alt_names = ['puppet', $facts['networking']['fqdn']],
  Variant[Boolean, Stdlib::Fqdn] $certname = true,
) {
  include puppet::server::install
  include puppet::globals
  include puppet::params

  $import_cakey  = "${import_path}/ca_key.pem"
  $import_cacert = "${import_path}/ca_crt.pem"
  $import_cacrl  = "${import_path}/ca_crl.pem"
  $import_serial = "${import_path}/serial"

  $import_condition = [
    "test -f ${import_cakey}",
    "test -f ${import_cacert}",
    "test -f ${import_cacrl}",
  ]

  $cacert           = $puppet::globals::cacert
  $ca_public_files  = $puppet::globals::ca_public_files
  $ca_private_files = $puppet::globals::ca_private_files
  $serial           = $puppet::globals::serial

  $ca_files         = $ca_public_files + $ca_private_files

  $subject_alt_names_param = $dns_alt_names[0] ? {
    Stdlib::Fqdn => join(['--subject-alt-names', join($dns_alt_names, ',')], ' '),
    default      => '',
  }

  $certname_param = $certname ? {
    Stdlib::Fqdn => "--certname ${certname}",
    true         => "--certname ${facts['networking']['fqdn']}",
    default      => '',
  }

  # These PKI assets shold be cleaned up before CA import
  $timestamp = Timestamp.new().strftime('%Y%m%dT%H%M%S')
  $ca_files.each |Stdlib::Unixpath $path| {
    exec { "backup ${path}":
      path    => '/bin:/usr/bin',
      command => "mv -n ${path} ${path}.${timestamp}",
      onlyif  => ["test -f ${path}"] + $import_condition,
      unless  => "diff -q ${import_cacert} ${cacert}",
      before  => Exec['puppetserver ca import'],
    }
  }

  exec { 'puppetserver ca import':
    path    => '/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/bin:/usr/bin',
    command => "puppetserver ca import ${subject_alt_names_param} ${certname_param} --private-key ${import_cakey} --cert-bundle ${import_cacert} --crl-chain ${import_cacrl}", # lint:ignore:140chars
    onlyif  => $import_condition,
    creates => $cacert,
  }

  exec { "cat ${import_serial} > ${serial}":
    path    => '/bin:/usr/bin',
    onlyif  => "test -f ${import_serial}",
    unless  => "diff -q ${import_serial} ${serial}",
    require => Exec['puppetserver ca import'],
  }

  Class['puppet::server::install'] -> Exec['puppetserver ca import']
}
