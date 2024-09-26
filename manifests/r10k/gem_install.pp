# puppet::r10k::gem_install
#
# Installs R10K on the server using the `gem install` Exec resource to ensure it is actually installed.
#
# @summary R10K installation on the server.
#
# @example
#   include puppet::r10k::gem_install
#
# @param r10k_package_name The name of the R10K gem package.
# @param gem_path The path to the Gem executable.
# @param r10k_path The path where R10K executable will be installed.
#
class puppet::r10k::gem_install (
  String  $r10k_package_name = $puppet::params::r10k_package_name,
  Stdlib::Absolutepath $gem_path = $puppet::params::gem_path,
  Stdlib::Absolutepath $r10k_path = $puppet::params::r10k_path,
) inherits puppet::params {
  include puppet::agent::install
  include puppet::r10k::dependencies

  exec { 'r10k-installation':
    command => "${gem_path} install --no-document ${r10k_package_name}",
    creates => $r10k_path,
  }

  Class['puppet::agent::install'] -> Exec['r10k-installation']
  Class['puppet::r10k::dependencies'] -> Exec['r10k-installation']
}
