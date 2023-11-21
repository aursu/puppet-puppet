class { 'puppet::server::bootstrap::globals':
  access_data => lookup({ name => 'profile::puppet::deploy::access', default_value => [] }),
  ssh_config  => lookup({ name => 'profile::puppet::deploy::ssh_config', default_value => [] }),
}

class { 'puppet::server::bootstrap':
  platform_name => 'puppet8',
}
