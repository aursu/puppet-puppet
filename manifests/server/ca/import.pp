# @summary Import existing CA into current server
#
# Import existing CA into current server
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
  Stdlib::Unixpath
          $import_path,
  Array[Stdlib::Fqdn]
          $dns_alt_names = ['puppet', $::fqdn],
  Variant[
    Boolean,
    Stdlib::Fqdn
  ]       $certname      = true,
)
{
  include puppet::server::install
  include puppet::globals

  $cacert = $puppet::globals::cacert

  $import_cakey  = "${import_path}/ca_key.pem"
  $import_cacert = "${import_path}/ca_crt.pem"
  $import_cacrl  = "${import_path}/ca_crl.pem"

  $import_serial = "${import_path}/serial"
  $import_cert_inventory = "${import_path}/inventory.txt"

  $subject_alt_names_param = $dns_alt_names[0] ? {
    Stdlib::Fqdn => join(['--subject-alt-names', join($dns_alt_names, ',')], ' '),
    default      => '',
  }

  $certname_param = $certname ? {
    Stdlib::Fqdn => "--certname ${certname}",
    true         => "--certname ${::fqdn}",
    default      => '',
  }

  exec { 'puppetserver ca import':
    path    => '/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/bin:/usr/bin',
    command => "puppetserver ca import ${subject_alt_names_param} ${certname_param} --private-key ${import_cakey} --cert-bundle ${import_cacert} --crl-chain ${import_cacrl}", # lint:ignore:140chars
    onlyif  => [
      "test -f ${import_cakey}",
      "test -f ${import_cacert}",
      "test -f ${import_cacrl}",
    ],
    creates => $cacert,
  }

  Class['puppet::server::install'] -> Exec['puppetserver ca import']
}

