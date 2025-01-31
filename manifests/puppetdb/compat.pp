# @summary Resolves conflicts caused by duplicate PuppetDB read connection settings in `database.ini`.
#
# This class ensures that the PuppetDB package installation and the PuppetDB Puppet module 
# do not create conflicting entries for the `read-database` connection settings. It removes 
# the `database.ini` file generated during PuppetDB package installation to avoid errors 
# when PuppetDB is configured.
#
# @example
#   include puppet::puppetdb::compat
#
class puppet::puppetdb::compat inherits puppet::puppetdb::globals {
  $database_ini = "${puppet::puppetdb::globals::confdir}/database.ini"

  if $puppet::globals::use_compat_mode {
    include puppetdb

    #  Duplicate configuration entry: [:read-database :subname]
    exec { "rm -f ${database_ini}":
      path        => '/usr/bin:/bin',
      refreshonly => true,
      onlyif      => "grep -q read-database ${database_ini}",
      subscribe   => Package[$puppetdb::puppetdb_package],
      before      => Class['puppetdb::server::database'],
    }
  }
}
