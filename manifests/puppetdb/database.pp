# @summary Manages the PostgreSQL database setup for PuppetDB.
#
# The `puppet::puppetdb::database` class sets up a PostgreSQL database for PuppetDB,
# including user credentials, database creation, and the required `pg_trgm` extension.
# It ensures that the `puppetdb::database::postgresql` class is properly configured
# with database parameters and integrates with the `lsys_postgresql` module for server management.
#
# **Class Workflow:**
# - **Database Setup:** Configures the database name, user, and password for PuppetDB, with defaults
#   for easy deployment.
# - **Extension Management:** Adds the `pg_trgm` extension to enable trigram-based text search,
#   which is commonly used in PuppetDB for efficient data querying.
# - **Dependency Management:** Ensures the `lsys_postgresql` server is set up prior to the PuppetDB
#   database configuration and that the extension is created before PuppetDB accesses the database.
#
# @param database_name [String] The name of the database for PuppetDB. Defaults to 'puppetdb'.
# @param database_username [String] The username for connecting to the PuppetDB database. Defaults to 'puppetdb'.
# @param database_password [String] The password for the PuppetDB database user. Defaults to 'puppetdb'.
#
# **Dependencies:**
# - `lsys_postgresql`: Manages the PostgreSQL server setup.
# - `puppetdb::database::postgresql`: Configures the database-specific settings for PuppetDB.
# - `postgresql::server::extension`: Ensures the `pg_trgm` extension is installed.
#
# @example Basic usage
#   include puppet::puppetdb::database
#
# @example Custom database configuration
#   class { 'puppet::puppetdb::database':
#     database_name     => 'customdb',
#     database_username => 'customuser',
#     database_password => 'custompassword',
#   }
#
# This example sets up a custom database and user for PuppetDB, using the `customdb` database
# with `customuser` credentials.
#
class puppet::puppetdb::database (
  String $database_name = 'puppetdb',
  String $database_username = 'puppetdb',
  String $database_password = 'puppetdb',
) {
  include lsys_postgresql

  postgresql::server::extension { "${database_name}-pg_trgm":
    extension => 'pg_trgm',
    database  => $database_name,
  }

  class { 'puppetdb::database::postgresql':
    database_name     => $database_name,
    database_username => $database_username,
    database_password => $database_password,
    database_port     => "${lsys_postgresql::database_port}", # lint:ignore:only_variable_string
    manage_server     => false,
    manage_database   => true,
  }
  contain puppetdb::database::postgresql

  Class['lsys_postgresql'] -> Class['puppetdb::database::postgresql']
}
