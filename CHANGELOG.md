# Changelog

All notable changes to this project will be documented in this file.

## Release 1.0.0

⚠ **Breaking change: `puppet::config::webserver` no longer binds `0.0.0.0`.**

`ssl_host` now defaults to the host's first RFC 1918 private address instead of the wildcard, and the catalogue **fails** if the host has no private address and none was given, rather than falling back to a wildcard. Upgrading changes the address Puppet Server binds to on any host that relied on the old default. On a single-homed host the effective result is the same; on a multi-homed one, Puppet Server stops answering on every interface it happens to have - which is the point. Set `puppet::config::webserver::ssl_host` explicitly if you need a specific address, or `127.0.0.1` when a proxy fronts the service.

The reasoning: binding a wildcard puts a fleet's control plane on every interface a host has, including ones added after the fact. That is not a default a module should ship for this service, and the failure mode it creates is invisible until someone scans the wrong network.

**Features**

* **`puppet::nginx`** - front Puppet Server with an nginx TLS-terminating proxy, so client-certificate policy can be decided per request path. Certificate enrolment is inherently certificate-less: a node contacts the CA precisely because it has none yet, and a single Jetty listener applies one `client-auth` value to every path, so requiring certificates for catalogues also blocks enrolment. With this, `/puppet-ca` accepts a certificate-less client while everything else rejects one. Agents are unaffected - nginx answers on the port they already use, presenting the same certificate. `manage_nginx_core` follows the convention used elsewhere: true manages nginx core, false leaves it to whatever already owns it on the host.
* **`puppet::config::webserver::tls_offload`** - render a plain HTTP listener on loopback instead of an SSL one, for use with the above. When enabled, `client_auth`, `ssl_host`, `ssl_port` and the certificate paths are not rendered: the proxy owns all of it.
* **`puppet_auth_setting`** - new type and provider for settings in the `authorization` section of auth.conf, beside the `rules` list `puppet_auth_rule` owns. Exists because the rule type can only reach `authorization.rules`, leaving siblings such as `allow-header-cert-info` outside configuration management.
* **`puppet::server::ca::allow::allow_header_cert_info`** - manage that setting. `undef` by default, meaning unmanaged.
* **`puppet::server::ca::allow::restrict_csr_read`** - require authorisation to *read* certificate requests while leaving submission open. `GET` on `/puppet-ca/v1/certificate_request` returns a pending CSR and nothing in normal operation needs it; `PUT` is how a node enrols and must stay open. Default `false`, preserving the rule Puppet Server ships.
* **`puppet::globals::internal_ip`** - the host's first private address, computed once so that everything asking "what is this server reachable on" gets the same answer.

⚠ **Read before enabling the proxy.** Terminating TLS in nginx means Puppet Server no longer sees the client certificate: identity arrives as `X-Client-*` headers and Puppet Server must be told to trust them. Anything able to reach Puppet Server directly can then forge that identity, so the loopback binding stops being hygiene and becomes the control the whole arrangement rests on. Enable `tls_offload`, `puppet::nginx` and `allow_header_cert_info` together, or not at all.

**Bugfixes**

* `puppet_auth_rule` and `puppet_auth_setting` now share one parsed auth.conf document through `PuppetX::Puppetserver::AuthConf`. Previously each provider parsed its own copy and rendered it back over the whole file, so a catalogue containing both a rule change and a setting change would have the second flush silently discard the first.

**Dependencies**

* `aursu/bsys` >= 0.12.0, for `bsys::is_private_ip`.
* `aursu/nginx` and `aursu/lsys_nginx`, used only by `puppet::nginx`.

## Release 0.43.0

**Features**

* `puppet::profile::server` exposes **`autosign`**, defaulting to `false`, and passes it to the `puppet` class. Previously the setting reached `puppet.conf` only through the `puppet` class's own data default, so nothing between a site profile and the CA stated it — a security-relevant value was invisible at the layer operators actually read, and a change to module data would have altered CA behaviour on every server built from this profile. Documented as a security decision rather than a convenience: with autosign off, an unauthenticated certificate request produces only a pending CSR that an operator must approve; with it on, the same request yields an issued certificate. Accepts a path for policy-based autosigning. **Not** added to `puppet::profile::compiler`, which sets `sameca => false` and therefore runs no CA — a parameter there could only enable something with no effect.

**Bugfixes**

* ⚠ **`puppet::config::webserver` is now `contain`ed rather than `include`d, so a change to `webserver.conf` actually restarts the server.** `puppet::service` declares `Class['puppet::config'] ~> Service['puppet-server']`, and that edge only reaches resources *contained* in `puppet::config`. Under `include` the webserver class sat outside the containment boundary: the file was rewritten on disk and the running service kept the previous settings. The failure mode is quiet — the file is correct, the agent reports the change, and anyone verifying by reading the file concludes the setting is in force, while the service still has the old value until something else restarts it. Observed with `client-auth`, where the difference between `want` and `need` decides whether an unauthenticated TLS client is refused. The sibling `puppet::config::fileserver` was already contained; this brings the two into line.

## Release 0.42.0

**Bugfixes**

* **The active platform's apt source is now managed, not inferred.** `puppet::repo` declares it as an `apt::source` (new `manage_source`, default `true`), so it is a resource Puppet owns rather than a side effect of the release package. ⚠ Previously the package shipped `/etc/apt/sources.list.d/<platform>-release.list` and `Package['puppet-release']` being installed was the only thing checked — once installed it was never revisited, and anything that happened to the file afterwards was a state Puppet could not observe. Both failure modes were measured on this estate after `do-release-upgrade`: the file **renamed to `.list.distUpgrade`** leaving no live source at all, so the host silently stopped receiving agent updates while `apt update` still exited 0; and the file **surviving but naming the previous release** (`ubuntu22.04` on a host now running noble), so it pulled packages built for the old OS. One resource fixes both, because the suite comes from the OS fact on every run: a missing file is recreated, a stale one rewritten.
* The active platform's `do-release-upgrade` leftovers — `.sources`, `.list.distUpgrade`, `.list.save` — are removed, as the decommission loop already did for retired platforms. `.list` is deliberately excluded: that is the file `apt::source` writes.
* `Apt::Source` notifies the existing apt refresh. On the hosts this fixes the **package does not change at all** — that is the whole reason the source went unnoticed — so subscribing only to the package would have left a rewritten source with a stale index.
* New `$repo_keyring` in `puppet::globals`, and `source_keyring` on `puppet::repo`: OpenVox references `/etc/apt/keyrings/openvox-keyring.gpg` with `signed-by=`, while Puppet Inc keys live in `trusted.gpg.d` and their source line carries none — `undef` reproduces the original rather than inventing a reference.
* `notify_update => false` on the source, because this class already owns its refresh; leaving it on would queue a second `apt-get update` through `Class['apt::update']` for the same change.

**Known Issues**

## Release 0.41.0

**Features**

* `puppet::agent::schedule` now manages the Puppet agent **daemon** as well as the cron schedule, via `disable_daemon` and `daemon_service_name`. Left `undef`, `disable_daemon` follows `$enable` — the honest coupling, since cron and the daemon are two ways of scheduling the same agent and running both means they collide. The agent takes a run lock, so whichever starts second exits non-zero: at boot the daemon finds the cron-driven run's `agent_catalog_run.lock`, gives up, and systemd records `puppet.service` as **failed** for the rest of the host's life. Agent runs are unaffected, but the host keeps a permanently failed unit, and a fleet where every host has one is a fleet where `systemctl --failed` no longer means anything.
* The disabled branch uses `enable => mask`, not `false`, because **the agent package enables the daemon on install** — so without masking it returns on the next agent upgrade. The service is declared in **both** directions so that setting `disable_daemon => false` unmasks and starts it again, rather than leaving behind a masked unit the catalogue no longer mentions.
* ⚠ `provider => systemd` is named explicitly: Puppet's default on Debian is `debian`, which wraps update-rc.d, has no `maskable` feature and fails outright on `enable => mask`.

**Bugfixes**

**Known Issues**

## Release 0.40.1

**Bugfixes**

* `puppet::repo` no longer purges decommissioned release packages. Purging
  works, but the apt provider then runs `apt-mark manual <package>` against a
  package whose repository has just been removed; that exits 100 and fails the
  resource, taking every resource ordered after it with it - including the very
  file removals that decommission the repository. The work had already
  succeeded, so the run reported a failure for something it had done, and only
  the following run came back clean. Removing the apt source files explicitly,
  as 0.40.0 already does, is what retires the repository; the package state
  alone never did.

## Release 0.40.0

**Features**

* `puppet::repo` now removes the apt sources of decommissioned platforms, not
  just their packages: the apt source files are removed explicitly, including
  the ones dpkg does not own - a disabled `.sources`, a
  `.list.distUpgrade` or `.list.save` left by `do-release-upgrade`, and the
  version-specific `puppet<N>-keyring.gpg` - are removed with them. The shared
  OpenVox keyring and the `*-release.pref` files are deliberately kept, since
  openvox7 and openvox8 share them.
* `puppet::repo` refreshes apt after installing a release package on Debian.

**Bugfixes**

* Switching platform on Debian left the old repository active. `ensure =>
  absent` leaves a package in state `rc` with its conffiles, so
  `/etc/apt/sources.list.d/<platform>-release.list` survived and apt kept
  reading it - which meant an expired signing key kept failing `apt update` on a
  host whose platform had already been migrated.
* Switching platform on Debian failed the agent package on the same run with
  `E: Unable to locate package openvox-agent`. The new source was in place but
  its index had never been fetched, and the agent package is ordered directly
  after this class. It recovered only if something else refreshed apt before the
  next run.

## Release 0.39.2

**Features**

* Added end-to-end `r10k_crontab_decomission` parameter propagation through profile and setup classes

**Bugfixes**

* Wired `puppet::server::setup` to pass decommission mode into `puppet::r10k::crontab`
* Added default value for `puppet::r10k_crontab_decomission` in Hiera data

**Known Issues**

## Release 0.39.1

**Features**

**Bugfixes**

* Added `decomission` mode to `puppet::r10k::crontab` to remove cron entry when decommissioning
* Fixed class parameter documentation in `puppet::r10k::crontab`

**Known Issues**

## Release 0.39.0

**Features**

* Updated Bolt Puppetfile to include puppet/openvox_bootstrap module
* Updated bolt-project.yaml to version 0.38.0 and added openvox_bootstrap module reference
* Added bootstrap/bolt/keys and CA files to .gitignore for security

**Bugfixes**

* Fixed puppetdb_package variable assignment in https_config.pp to use globals class

**Known Issues**

## Release 0.38.0

**Features**

* Added puppet/openvox_bootstrap module dependency for OpenVox platform support
* Updated agent install plan to use openvox_bootstrap::install task for OpenVox installations
* Enhanced install plan logic to differentiate between standard Puppet and OpenVox platform installations

**Bugfixes**

**Known Issues**

## Release 0.37.0

**Features**

* PDK upgrade to version 3.6.1
* Removed legacy compat_mode from repo class

**Bugfixes**

* Fixed rubocop convention violations:
  - Call super without arguments when signature is identical
  - Use each_key instead of each with unused block argument
  - Remove parentheses around logical expressions
  - Fix duplicate example descriptions in specs
  - Use safe_load_file instead of safe_load with File.read

## Release 0.36.0

**Features**

* Added support for OpenVox platforms (openvox7, openvox8) - Vox Pupuli fork of Puppet
* Added support for new operating systems:
  - Rocky Linux 10
  - Debian 12
  - SLES 15
  - Fedora 41
  - Amazon Linux 2023
* Refactored `puppet::globals` class to handle platform-specific package names and repositories
* Added `is_openvox` flag to distinguish between standard Puppet and OpenVox platforms
* Moved `agent_package_name` and `server_package_name` from `puppet::params` to `puppet::globals`
* Added comprehensive version codename and package build logic for all supported platforms
* Added `puppet::puppetdb::globals` class for PuppetDB-specific global settings
* Added support for OpenVox-specific packages: openvox-agent, openvox-server, openvoxdb, openvoxdb-termini
* Added comprehensive RSpec tests for all new features:
  - Repository URL validation for all platforms and operating systems
  - Package name validation for different platforms
  - Version codename and package build testing
  - Platform-specific behavior testing

**Bugfixes**

* Fixed missing documentation for class parameters across multiple classes
* Fixed inheritance from `puppet::params` to `puppet::globals` in agent and server install classes
* Fixed PuppetDB globals to properly reference terminus package names

**Known Issues**

## Release 0.35.0

**Features**

* Dropped support for Puppet 5 and Puppet 6 platforms
* Updated Puppet::Platform type to only include puppet7 and puppet8
* Removed puppet5 and puppet6 platform-specific code and logic
* Simplified configuration by removing legacy puppet5/puppet6 compatibility code
* Updated task definitions to only support puppet7 and puppet8 collections

**Bugfixes**

**Known Issues**

## Release 0.34.0

**Features**

* Updated r10k module dependency to version 14.3.0 for improved functionality
* Updated minimum r10k version requirement to >= 14.0.0 < 15.0.0 in metadata
* Updated Bolt bootstrap configuration to use r10k 14.3.0
* Updated test fixtures to use latest r10k version

**Bugfixes**

**Known Issues**

## Release 0.3.3

**Features**

* Added external facts standard directories management
* Added puppet::globals to support few major versions of Puppet
* Added puppet::profile::agent to setup Puppet agent properly
* Added ca_server into puppet agent config
* Added flag to enable/disable cron jobs
* Updated dependencies

**Bugfixes**

* Added /usr/local/bin into path for Puppet cron jobs

**Known Issues**

## Release 0.3.7

**Features**

* Switched from default Puppet 5 to Puppet 7 for Bolt plans
* Added ability to separate Puppet Server, Puppet CA and PuppetDB
* Added compiler mode of Puppet Server
* Added Bolt plan puppet::agent::hostname to set hostname on target hosts
* PDK upgrade

**Bugfixes**

* Updated dependencies versions
* Bugfix: wrong parameters count

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

## Release 0.28.6

**Features**

* Added `puppet::r10k::run` class containment into `puppet::server::setup`

**Bugfixes**

* Added custom `puppet-terminus-puppetdb` puppetdb termini package for Ubuntu 24.04
* Added `hiera-eyaml` and `scanf` gems installation for Ubuntu 24.04
* Added correct PuppetDB `confdir` and `ssl_dir` paths
* Adjusted PuppetDB `ssl_dir` path inside `puppet::puppetdb::https_config` and
  inside `puppet::puppetdb`
* Truncate PuppetDB's `database.ini` to avoid duplicate declaration for `read-database` section
* Adjusted PuppetDB `vardir` path inside `puppetdb::server::global`

**Known Issues**

## Release 0.29.5

**Features**

* Added Ubuntu 24.04 support

**Bugfixes**

* PuppetDB default version for Ubuntu 24.04
* Adjusted the `puppet::params` class usage as it includes `puppetdb::params`,
  and consequently, `puppetdb::globals` as well
* Addressed puppetdb terminus version setup
* Addee `puppetserver.conf` for puppetserver compat mode

**Known Issues**

## Release 0.31.3

**Features**

* Added ability to avoid use OS distro packages
* Added ability to use Ubuntu 24.04 as is (no compat mode)

**Bugfixes**

* r10k install dependency
* Defined Puppet distro default versions
* Corrected `puppet::server::clean`
* Corrected Bolt plans

**Known Issues**

## Release 0.33.1

**Features**

**Bugfixes**

* Compatibility with r10k >= 13.0.0 and Puppet 7
* Disabled compatibility mode for Ubuntu as vendor packages are already available
* Fixed plan `puppet::cert::clean`
* Fixed `apt` module dependency version
* Corrected Bolt plan `puppet::bootstrap`

**Known Issues**

## Release 0.33.3

**Features**

**Bugfixes**

* Corrected Bolt plan `puppet::bootstrap` (run plan `facts` on each target)

**Known Issues**
