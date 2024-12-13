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

## Release 0.17.2

**Features**

* Updated documentation

**Bugfixes**

* Added CA serial file sync to avoid new certificates automatic revocation
* Do not manage Puppet service init template only on RedHat 7 and below

**Known Issues**

## Release 0.18.0

**Features**

* Added Ubuntu into supported OSes

**Bugfixes**

**Known Issues**

## Release 0.18.1

**Features**

**Bugfixes**

* Disable crontab manage during PuppetDB bootstrap

**Known Issues**

## Release 0.19.0

**Features**

* Added `certname` parameter into profiles

**Bugfixes**

**Known Issues**

## Release 0.19.1

**Features**

* Added plan `puppet::agent::run` with only puppet agent output
* Added ability to set up specific hostname in `puppet::agent::hostname`
* Updated some documentation

**Bugfixes**

**Known Issues**

## Release 0.19.2

**Features**

* Added ability to disable upstream repo management
  Flag `puppet::manage_repo`

**Bugfixes**

**Known Issues**

## Release 0.19.5

**Features**

**Bugfixes**

* Make dependency on puppetlabs/puppet_agent >= 4.20.0 as it has environment validation fix
* Moved the decommissioning of other Puppet platform repositories under the repository management section
* Added ability to disable upstream repo management into profiles

**Known Issues**

## Release 0.19.6

**Features**

* Added Bolt plan `puppet::server::sync`

**Bugfixes**

**Known Issues**

## Release 0.19.8

**Features**

* Added Bolt task and plan `puppet::repo`

**Bugfixes**

* Added collection parameter into Bolt plan `puppet::server::sync`

**Known Issues**

## Release 0.19.9

**Features**

* Updated `aursu/lsys_postgresql` module to 0.50.4

**Bugfixes**

**Known Issues**

## Release 0.20.6

**Features**

* Repo installation process isolation

**Bugfixes**

* Fixed SSH access configuration compilation issue
* Corrected Puppet platform repository URL
* Added support for r10k installation on Puppet 7
* Fixed `gem install` command by adding the `--no-document` option
* Fixed puppetdb bootstrap error for Puppet 7
* Fixed node bootstrap Bolt plan `puppet::bootstrap` for Puppet 7
* Fix into startup issue for PuppetDB

**Known Issues**

## Release 0.21.0

**Features**

* Renamed `puppet_server` variable to avoid conflicts with the `puppet_server` fact.

**Bugfixes**

* Set `ssl_set_cert_paths` flag to true for PuppetDB installation

**Known Issues**

## Release 0.22.1

**Features**

* Added TLS assets setup for PuppetDB web service HTTPS

**Bugfixes**

**Known Issues**

## Release 0.22.5

**Features**

* Moved the `r10k_vardir` variable into `puppet::params`.
* Added the ability to define a custom value for `r10k_cachedir`.
* Added filesystem class to manage directories

**Bugfixes**

* Bugfix: added proper dependencies for PuppetDB $ssl_dir File resource
* Bugfix: added certname PEM files propagation to clientcert PEM files

**Known Issues**

## Release 0.23.1

**Features**

- **Ubuntu 24.04 Support**: Updated the `puppetlabs/puppet_agent` dependency to ensure compatibility with Ubuntu 24.04.
- **Enhanced Puppet Message Output**: Integrated Puppet messages output into the `puppet::server::bootstrap` plan, among other plans, for improved debugging and transparency.

**Bugfixes**

*No bug fixes were addressed in this release.*

**Known Issues**

*No new known issues have been identified.*

## Release 0.25.1

**Features**

* Added `puppet::agent` Puppet agent installation class
* Added PuppetDB database class `puppet::puppetdb::database`

**Bugfixes**

**Known Issues**

## Release 0.25.6

**Features**

* Added the `manage_gem` flag to allow disabling custom gem management.
* Disabled Puppet Platform repository management for Ubuntu 24.04
* Added Apt update into server bootstrap for Debian based OSes

**Bugfixes**

* renamed plan parameter name from `nodes` into `hosts`
* For Debian system added management for directoires `/usr/share/puppet`
  and `/usr/share/puppet/modules`
* Added user/group `puppet` management for Debian OSes

**Known Issues**

## Release 0.26.4

**Features**

* Added configuration file `/etc/puppet/puppetserver/conf.d/auth.conf` support
  for `puppet_auth_rule` custom type for 
* Adjusted directories for non-puppet-platform distributions
* Adjusted directories inside configuration files
* Set `gem` provider for package `r10k`

**Bugfixes**

**Known Issues**

## Release 0.27.1

**Features**

* Hardcoded `/etc/puppetlabs/puppet/keys` as only Puppet keys location

**Bugfixes**

* Added `hiera-eyaml` into server installation for non-puppet-platform
  distributions

**Known Issues**

## Release 0.28.2

**Features**

* Added `puppet::r10k::run` class containment into `puppet::server::setup`

**Bugfixes**

* Added custom `puppet-terminus-puppetdb` puppetdb termini package for Ubuntu 24.04
* Added `hiera-eyaml` and `scanf` gems installation for Ubuntu 24.04
* Added correct PuppetDB `confdir` and `ssl_dir` paths

**Known Issues**
