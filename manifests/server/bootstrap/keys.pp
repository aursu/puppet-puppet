# @summary Bootstrap eYAML keys
#
# Bootstrap eYAML keys from current directory into production environment
# This is intended to be run via `puppet apply` command
#
# @example
#   include puppet::server::bootstrap::keys
class puppet::server::bootstrap::keys inherits puppet::params {
  require puppet::server::install
  include puppet::server::keys
  include puppet::server::bootstrap::globals

  $eyaml_keys_path = $puppet::params::eyaml_keys_path
  $eyaml_public_key = $puppet::params::eyaml_public_key
  $eyaml_private_key = $puppet::params::eyaml_private_key
  $cwd = $puppet::server::bootstrap::globals::cwd

  exec {
    default:
      path    => '/usr/bin:/bin',
      require => File[$eyaml_keys_path],
      cwd     => $cwd,
      ;
    "cp -a keys/public_key.pkcs7.pem ${eyaml_keys_path}/${eyaml_public_key}":
      onlyif  => 'test -f keys/public_key.pkcs7.pem',
      creates => "${eyaml_keys_path}/${eyaml_public_key}",
      before  => File["${eyaml_keys_path}/${eyaml_public_key}"],
      ;
    "cp -a keys/private_key.pkcs7.pem ${eyaml_keys_path}/${eyaml_private_key}":
      onlyif  => 'test -f keys/private_key.pkcs7.pem',
      creates => "${eyaml_keys_path}/${eyaml_private_key}",
      before  => File["${eyaml_keys_path}/${eyaml_private_key}"],
      ;
  }

  Class['puppet::server::install'] -> Class['puppet::server::keys']
}
