# Changelog

All notable changes to this project will be documented in this file.

## Release 0.1.6

**Features**

* Added external facts standard directories management

**Bugfixes**

**Known Issues**

## Release 0.1.7

**Features**

* Updated dependencies

**Bugfixes**

**Known Issues**

## Release 0.2.0

**Features**

* Added puppet::globals to support few major versions of Puppet

**Bugfixes**

**Known Issues**

## Release 0.3.0

**Features**

* Added puppet::profile::agent to setup Puppet agent properly

**Bugfixes**

**Known Issues**

## Release 0.3.1

**Features**

* Added ca_server into puppet agent config

**Bugfixes**

**Known Issues**

## Release 0.3.2

**Features**

**Bugfixes**

* Added /usr/local/bin into path for Puppet cron jobs

**Known Issues**

## Release 0.3.3

**Features**

* Added flag to enable/disable cron jobs

**Bugfixes**

**Known Issues**

## Release 0.3.4

**Features**

* Switched from default Puppet 5 to Puppet 7 for Bolt plans

**Bugfixes**

* Updated dependencies versions

**Known Issues**

## Release 0.3.5

**Features**

**Bugfixes**

* Bugfix: wrong parameters count

**Known Issues**

## Release 0.3.6

**Features**

* Added ability to separate Puppet Server, Puppet CA and PuppetDB
* Added compiler mode of Puppet Server

**Bugfixes**

**Known Issues**

## Release 0.3.7

**Features**

* Added Bolt plan puppet::agent::hostname to set hostname on target hosts
* PDK upgrade

**Bugfixes**

**Known Issues**

## Release 0.3.8

**Features**

* Added ability to disable verbose mode in cron

**Bugfixes**

**Known Issues**

## Release 0.3.9

**Features**

* PDK update to 2.5.0

**Bugfixes**

**Known Issues**

## Release 0.4.0

**Features**

* Added separate class for PuppetDB

**Bugfixes**

* Fixed bug manage_database flag for PuppetDB

**Known Issues**

## Release 0.4.1

**Features**

* For profile puppet::profile::server added ability to override default
  ENC environment name

**Bugfixes**

**Known Issues**

## Release 0.4.2

**Features**

* Added timeout 900 seconds for r10k exec

**Bugfixes**

**Known Issues**

## Release 0.4.3

**Features**

**Bugfixes**

* Bugfix: agentrun script installation

**Known Issues**

## Release 0.5.0

**Features**

**Bugfixes**

* Bugfix: disable import ca resource

**Known Issues**

## Release 0.5.1

**Features**

* Added ability to setup static certname

**Bugfixes**

**Known Issues**

## Release 0.5.2

**Features**

* Added ability to setup r10k crontab

**Bugfixes**

**Known Issues**

## Release 0.6.0

**Features**

* Added webserver.conf with SSL settings
* PDK upgrade to 2.6.1

**Bugfixes**

**Known Issues**

## Release 0.6.1

**Features**

* Added flag to set on/off webserver.conf management

**Bugfixes**

**Known Issues**

## Release 0.7.1

**Features**

* Added fileserver configuration management

**Bugfixes**

**Known Issues**

## Release 0.8.0

**Features**

* Switched to lsys_postgresql module

**Bugfixes**

**Known Issues**

## Release 0.8.1

**Features**

* Added version compilation for RPM-based systems

**Bugfixes**

**Known Issues**

## Release 0.9.0

**Features**

* General Puppet profile

**Bugfixes**

**Known Issues**

## Release 0.10.0

**Features**

* Integrated Puppet bootstrap

**Bugfixes**

**Known Issues**

## Release 0.11.0

**Features**

* Set Puppet 8 as default version
* Added `agent_version` parameter into `puppet::server::bootstrap`
* PDK upgrade to 3.0.0
* Force to use Hiera for SSH access_data and client configuration

**Bugfixes**

**Known Issues**

## Release 0.11.1

**Features**

* Added `node_environment` parameter into `puppet::server::bootstrap`
* removed parameter `-t rsa` from `ssh-keyscan` command to fetch all host keys
* Added flag `use_ssh` into `puppet::server::bootstrap` class in case if r10k
does not require SSH keys for Puppet code deployment.

**Bugfixes**

* Added PDK ignore record `/bootstrap`
  see https://www.puppet.com/docs/pdk/2.x/pdk_testing.html#ignoring-files-during-module-validation
* Added proper resource apply order during server installation

**Known Issues**

## Release 0.12.0

**Features**

* Added into Bolt project Puppet bootstrap module `bootstrap_assets`

**Bugfixes**

**Known Issues**

## Release 0.13.0

**Features**

* Added into Bolt plans parmeters `use_ssh` and `bootstrap_path`

**Bugfixes**

**Known Issues**

## Release 0.13.1

**Features**

* Added rspec testing for r10k run during bootstrap

**Bugfixes**

* Added dependency of r10k run on SSH config

**Known Issues**

## Release 0.14.0

**Features**

* Set `cwd` to be the same as `bootstrap_path` by default.
* Added a class to set up the bootstrap directory on the Puppet server.

**Bugfixes**

* Removed the dependency of SSH configuration bootstrap process on eyaml keys
and Hiera configuration.
* Excluded PuppetDB settings from the Puppet configuration during
the bootstrap stage.

**Known Issues**

## Release 0.14.1

**Features**

* Added ability to install PuppetDB on Puppet compiler
* Added ENC bootstrap repo into bootstrap process

**Bugfixes**

**Known Issues**

## Release 0.15.0

**Features**

* Added ability to pass `certname` during bootstrap

**Bugfixes**

**Known Issues**

## Release 0.16.0

**Features**

* Added puppet_bootstrap::puppetdb Bolt plan for initializing PuppetDB.
* Introduced the ability to provide `dns_alt_names` during Puppet server
bootstrap
* Added `puppet::profile::puppetdb` profile, offering a predefined set of
configurations for easier PuppetDB integration
* Introduced `puppet_bootstrap::puppetdb::node` Bolt plan to authorise PuppetDB
node on Puppet server.
* Added support for specifying `certname` during PuppetDB bootstrap

**Bugfixes**

**Known Issues**