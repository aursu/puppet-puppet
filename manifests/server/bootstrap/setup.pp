# @summary Setup bootstrap and cwd paths
#
# Setup bootstrap and cwd paths
#
# @example
#   include puppet::server::bootstrap::setup
class puppet::server::bootstrap::setup {
  include puppet::server::bootstrap::globals

  $bootstrap_path = $puppet::server::bootstrap::globals::bootstrap_path
  $cwd = $puppet::server::bootstrap::globals::cwd

  exec { "mkdir -p ${bootstrap_path}":
    cwd     => '/',
    path    => '/usr/bin:/bin',
    creates => $bootstrap_path,
    before  => File[$bootstrap_path],
  }

  file { [$bootstrap_path, "${bootstrap_path}/ca", "${bootstrap_path}/keys"]:
    ensure => directory,
  }

  if $cwd and $cwd != $bootstrap_path {
    exec { "mkdir -p ${cwd}":
      cwd     => '/',
      path    => '/usr/bin:/bin',
      creates => $cwd,
    }

    file { $cwd:
      ensure => directory,
    }
  }
}
