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

  $environmentpath = $puppet::params::environmentpath
  $cwd = $puppet::server::bootstrap::globals::cwd

  # default production environment
  $env_path = "${environmentpath}/production"
  $data_path = "${env_path}/data"

  file { [$environmentpath, $env_path, $data_path]:
    ensure  => 'directory',
    require => Class['puppet::server::install'],
  }

  exec {
    default:
      path => '/usr/bin:/bin',
      cwd  => $cwd,
      ;
    "cp -a hiera.yaml ${env_path}/hiera.yaml":
      onlyif  => 'test -f hiera.yaml',
      unless  => "grep -q secrets.eyaml ${env_path}/hiera.yaml",
      require => [
        File[$env_path],
        Class['puppet::server::bootstrap::setup'],
      ],
      before  => File["${env_path}/hiera.yaml"],
      ;
    "cp -a data/secrets.eyaml ${data_path}/secrets.eyaml":
      onlyif  => 'test -f data/secrets.eyaml',
      creates => "${data_path}/secrets.eyaml",
      require => [
        File[$data_path],
        Class['puppet::server::bootstrap::setup'],
      ],
      before  => File["${data_path}/secrets.eyaml"],
      ;
  }

  file {
    default:
      mode  => '0440',
      group => 'puppet',
      ;
    "${env_path}/hiera.yaml": ;
    "${data_path}/secrets.eyaml": ;
  }
}
