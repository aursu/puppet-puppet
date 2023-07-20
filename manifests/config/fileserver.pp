# @summary Define file serving from Puppet server
#
# Define file serving from Puppet server
#
# [Adding file server mount points](https://www.puppet.com/docs/puppet/7/file_serving.html)
# [fileserver.conf: Custom fileserver mount points](https://www.puppet.com/docs/puppet/7/config_file_fileserver.html)
#
# @param mount_points
#   
#
# @example
#   include puppet::config::fileserver
class puppet::config::fileserver (
  Hash[Pattern[/^[a-zA-Z0-9_]+$/], Stdlib::Absolutepath] $mount_points = {},
) {
  include puppet::params
  $fileserverconfig = $puppet::params::fileserverconfig

  if size($mount_points) > 0 {
    file { $fileserverconfig:
      ensure  => file,
      content => template('puppet/fileserver.conf.erb'),
    }
  }
}
