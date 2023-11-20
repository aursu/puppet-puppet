# puppet::service
#
# Puppet server service management
#
# @summary Puppet server service management
#
# @example
#   include puppet::service
#
# @param server_service_ensure
# @param server_service_enable
# @param service_name
#
# @param manage_init_config
#   Whether to manage init configuration file
#
# @param init_config_path
#   Full path to init configuration file (either /etc/sysconfig/puppetserver or
#   /etc/default/puppetserver, depending on your distribution)
#
# @param init_config_template
#   EPP template to setup Puppet server init configuration file from
#
# @param tmpdir
#
# @param min_heap_size
#   Sets the minimum and initial size (in bytes) of the heap (aka -XX:MinHeapSize, -Xms)
#   https://developers.redhat.com/articles/2021/09/09/how-jvm-uses-and-allocates-memory
#
# @param max_heap_size
#   Specifies the maximum size (in bytes) of the memory allocation pool (aka -XX:MaxHeapSize, -Xmx)
#
class puppet::service (
  String  $server_service_ensure = $puppet::server_service_ensure,
  Boolean $server_service_enable = $puppet::server_service_enable,
  String  $service_name = $puppet::params::service_name,
  Boolean $manage_init_config = $puppet::params::manage_init_config,
  Stdlib::Unixpath $init_config_path = $puppet::params::init_config_path,
  Optional[String] $init_config_template = $puppet::params::init_config_template,
  Stdlib::Unixpath $tmpdir = '/tmp',
  Puppet::JavaSize $min_heap_size = '2g',
  Puppet::JavaSize $max_heap_size = '2g',
) inherits puppet::params {
  include puppet::server::install
  include puppet::enc
  include puppet::config
  include puppet::server::ca::allow

  $tmp_mountpoint_noexec = $puppet::params::tmp_mountpoint_noexec

  # Try to fix `tmp directory mounted noexec` issue automatically
  # https://www.puppet.com/docs/puppet/8/server/known_issues.html#tmp-directory-mounted-noexec
  if $tmpdir == '/tmp' and $tmp_mountpoint_noexec {
    $java_io_tmpdir = '/var/tmp'
  }
  else {
    $java_io_tmpdir = $tmpdir
  }

  if $manage_init_config and $init_config_template {
    file { $init_config_path:
      ensure  => file,
      content => epp($init_config_template, {
          tmpdir        => $java_io_tmpdir,
          min_heap_size => $min_heap_size,
          max_heap_size => $max_heap_size,
      }),
      before  => Service['puppet-server'],
    }
  }

  service { 'puppet-server':
    ensure => $server_service_ensure,
    name   => $service_name,
    enable => $server_service_enable,
  }

  Class['puppet::server::install'] ~> Service['puppet-server']
  Class['puppet::config'] ~> Service['puppet-server']
  Class['puppet::server::ca::allow'] ~> Service['puppet-server']
  Class['puppet::enc'] -> Service['puppet-server']
}
