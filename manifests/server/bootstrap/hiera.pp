# @summary Bootstrap Hiera
#
# Bootstrap Hiera from current directory into production environment
# This is intended to be run via `puppet apply` command
#
# @example
#   include puppet::server::bootstrap::hiera
class puppet::server::bootstrap::hiera inherits puppet::params {
  require puppet::server::install
  include puppet::server::bootstrap::globals
  include puppet::server::bootstrap::setup
  include puppet::server::setup::filesystem

  $environmentpath = $puppet::params::environmentpath
  $cwd = $puppet::server::bootstrap::globals::cwd

  # default production environment
  $env_path = "${environmentpath}/production"
  $data_path = "${env_path}/data"

  file { [$env_path, $data_path]:
    ensure  => 'directory',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0750',
    require => Class['puppet::server::install'],
  }

  exec {
    default:
      path    => '/usr/bin:/bin',
      cwd     => $cwd,
      require => [
        File[$data_path],
        Class['puppet::server::bootstrap::setup'],
      ],
      ;
    "cp -a hiera/common.yaml ${data_path}/common.yaml":
      onlyif => 'test -f hiera/common.yaml',
      unless => "diff -q hiera/common.yaml ${data_path}/common.yaml",
      before => File["${data_path}/common.yaml"],
      ;
    "cp -a hiera/secrets.eyaml ${data_path}/secrets.eyaml":
      onlyif => 'test -f hiera/secrets.eyaml',
      unless => "diff -q hiera/secrets.eyaml ${data_path}/secrets.eyaml",
      before => File["${data_path}/secrets.eyaml"],
      ;
  }

  file {
    default:
      mode  => '0440',
      group => 'puppet',
      ;
    "${data_path}/common.yaml": ;
    "${data_path}/secrets.eyaml": ;
  }
}
