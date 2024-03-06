# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::server::bootstrap::ssh
class puppet::server::bootstrap::ssh inherits puppet::params {
  include puppet::server::bootstrap::globals
  include puppet::server::bootstrap::setup

  $access_data = $puppet::server::bootstrap::globals::access_data
  $ssh_access_config = $puppet::server::bootstrap::globals::ssh_access_config
  $ssh_config  = $puppet::server::bootstrap::globals::ssh_config
  $cwd = $puppet::server::bootstrap::globals::cwd

  $ssh_keyscan_package = $facts['os']['family'] ? {
    'Debian' => 'openssh-client',
    default  => 'openssh-clients',
  }

  package { $ssh_keyscan_package:
    ensure => 'present',
  }

  file { '/root/.ssh':
    ensure => 'directory',
    mode   => '0700';
  }

  # Update ~/.ssh/known_hosts if gitservers.txt exists
  exec { 'ssh-keyscan -f gitservers.txt >> /root/.ssh/known_hosts':
    path    => '/usr/bin:/bin',
    onlyif  => 'test -f gitservers.txt',
    cwd     => $cwd,
    unless  => 'grep -f gitservers.txt /root/.ssh/known_hosts',
    require => [
      Package[$ssh_keyscan_package],
      File['/root/.ssh'],
      Class['puppet::server::bootstrap::setup'],
    ],
  }

  if $ssh_access_config[0] or $ssh_config[0] {
    openssh::ssh_config { 'root':
      ssh_config => $ssh_config + $ssh_access_config,
    }
  }

  if $access_data[0] {
    $access_data.each |$creds| {
      $key_name    = $creds['name']
      $sshkey_type = $creds['sshkey_type'] ? { String => $creds['sshkey_type'], default => 'ed25519' }

      openssh::priv_key { $key_name:
        user_name   => 'root',
        key_prefix  => $creds['key_prefix'],
        sshkey_type => $sshkey_type,
        key_data    => $creds['key_data'],
      }
    }
  }
}
