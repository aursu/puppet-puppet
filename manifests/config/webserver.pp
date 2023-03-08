# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include puppet::config::webserver
class puppet::config::webserver {
  # https://www.puppet.com/docs/puppet/7/server/config_file_webserver.html
  # https://github.com/puppetlabs/trapperkeeper-webserver-jetty9/blob/main/doc/jetty-config.md
  file { '/etc/puppetlabs/puppetserver/conf.d/webserver.conf':
    ensure  => file,
    content => template('puppet/webserver.conf.erb'),
  }
}
