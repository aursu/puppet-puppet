# @summary Ensures compatibility and proper setup for Puppet Server
#
# This class addresses specific compatibility issues and prepares the Puppet Server environment. 
# It ensures required directories exist, installs necessary Ruby gems for Puppet Server, and configures 
# `puppetserver.conf` to include settings such as additional Ruby load paths.
# This makes it possible to install puppetdb-termini package from Ubuntu 22.04 on Ubuntu 24.04
#
# @example
#   include puppet::server::compat
class puppet::server::compat inherits puppet::params {
  $gem_home = $puppet::params::server_gem_home
  $config   = $puppet::params::config

  # Ensures required directories exist to prevent errors during puppetserver package installation, e.g.
  # error creating symbolic link '/usr/share/puppet/modules/mailalias.dpkg-tmp': No such file or directory
  file {
    ['/usr/share/puppet',
    '/usr/share/puppet/modules']:
      ensure => directory,
      before => Package['puppet-server'],
  }

  # Installs required Puppet Server gems
  # Lookup using eyaml lookup_key function is only supported when the hiera_eyaml library is present
  exec {
    default:
      path    => '/usr/bin:/bin',
      require => Package['puppet-server'],
      ;
    'puppetserver gem install hiera-eyaml --no-document --version 4.2.0':
      creates => "${gem_home}/gems/hiera-eyaml-4.2.0",
      ;
    'puppetserver gem install scanf --no-document --version 1.0.0':
      creates => "${gem_home}/gems/scanf-1.0.0",
      ;
  }

  # setup puppetserver.conf (Ubuntu 24.04) with puppetdb-termini from 22.04
  # include /opt/puppetlabs/puppet/lib/ruby/vendor_ruby into ruby-load-path
  file { "${config}/puppetserver.conf":
    ensure  => file,
    content => template('puppet/puppetserver.conf.erb'),
    require => Package['puppet-server'],
  }
}
