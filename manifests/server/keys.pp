# @summary Set up eYAML keys properties
#
# Set up proper permissions for EYAML keys and the paths leading to them.
#
# @example
#   include puppet::server::keys
class puppet::server::keys inherits puppet::params {
  $eyaml_keys_path = $puppet::params::eyaml_keys_path
  $eyaml_public_key = $puppet::params::eyaml_public_key
  $eyaml_private_key = $puppet::params::eyaml_private_key

  # Hardening of Hiera Eyaml keys
  file { $eyaml_keys_path:
    ensure => directory,
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0500',
  }

  # poka-yoke
  if '/etc/puppetlabs/puppet/' in $eyaml_keys_path {
    File <| title == $eyaml_keys_path |> {
      recurse => true,
      purge   => true,
    }
  }

  [$eyaml_public_key, $eyaml_private_key].each |$key| {
    file { "${eyaml_keys_path}/${key}":
      owner => 'puppet',
      group => 'puppet',
      mode  => '0400',
    }
  }
}
