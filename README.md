# puppet

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with `puppet`](#setup)
    * [What `puppet` affects](#what-puppet-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with puppet](#beginning-with-puppet)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This Puppet module is primarily designed to manage the Puppet server itself,
automating its configuration, deployment, and maintenance tasks. This ensures
the Puppet server operates efficiently and remains up-to-date.

Additionally, the module includes functionality to manage the Puppet agent as well.

## Setup

This module can be utilized in two primary ways:

1. **As a Regular Puppet Module** (e.g., included in a Puppetfile)

   For direct inclusion in your Puppet environment, specify the module in your Puppetfile as follows:

   ```
   mod 'puppet',
     git: 'https://github.com/aursu/puppet-puppet.git',
     tag: 'v0.19.1'
   ```

   Alternatively, you can specify the version directly if it’s available from the module repository on [Puppet Forge](https://forge.puppet.com/modules/aursu/puppet/readme):

   ```
   mod 'aursu/puppet', '0.19.1'
   ```

2. **As a Puppet Server Bootstrap Tool Using Puppet Bolt**

   The module includes a Bolt project located in the `bootstrap/bolt` subfolder. Within this project, there is a Bolt plan named `puppet_bootstrap::server` that is specifically designed for bootstrapping a Puppet server.

   Using this setup with Puppet Bolt facilitates a more efficient and straightforward installation process for the Puppet server. This method provides a predefined sequence of actions that automate much of the manual setup, streamlining the deployment of Puppet server environments. It also significantly reduces the complexity of the initial server configuration.

   Initiate the bootstrapping and subsequent Puppet agent run in the production environment with the following commands:

   ```
   bolt plan run puppet_bootstrap::server -t puppetservers
   bolt plan run puppet_agent::run -t puppetservers environment=production
   ```

   For a more detailed description, refer to the [`bootstrap`](bootstrap/README.md) directory.

### What `puppet` affects

When integrated into a Puppet catalog to configure a Puppet server, the `puppet` module offers comprehensive control over several crucial configurations and components of both the Puppet server and the overall Puppet infrastructure:

### Setup Requirements **OPTIONAL**

### Beginning with `puppet`

## Usage

### r10k Cache Directory Setup

To configure a custom cache directory for `r10k` instead of the default (`/var/cache/r10k`, as defined in `puppet::params`), there are a few options:

1. **Define the `r10k_cachedir` parameter**:
   - If the `puppet::profile::server` profile is in use, you can set the `r10k_cachedir` parameter to the desired cache directory.
   - Similarly, if the `puppet::profile::puppet` profile is in use, you can also define this parameter for that profile.

2. **Set the global variable `puppet::globals::r10k_cachedir`**:
   - Alternatively, define the global variable `puppet::globals::r10k_cachedir`. This corresponds to the `r10k_cachedir` parameter in the `puppet::globals` class, allowing you to override the default cache directory across the entire configuration. This option is particularly useful when Bolt plans, such as `puppet_bootstrap::server` or `puppet::server::bootstrap`, are in use.

### Adding r10k to Cron

To schedule the `r10k` command in `cron`, use the `puppet::r10k_crontab_setup` flag. Set this flag to `true` to enable the setup of `r10k` in the crontab.

### Puppet Agent Bootstrap

The `puppet::agent::bootstrap` class is responsible for bootstrapping a Puppet node. It performs the following steps:

1. **First Run:**
   It executes the `puppet agent --test` command to initiate the creation of a Puppet private key and request a certificate from the Puppet server.

2. **Subsequent Runs:**
   On subsequent executions, it attempts to download the certificate from the Puppet server. If the certificate is not yet available, the agent will continue to attempt fetching it on each run until the certificate is successfully retrieved.

3. **Handling `certname`:**
   If a `certname` is specified during the certificate request, the private key and certificate will be propagated into the appropriate locations using the `fqdn` (fully qualified domain name), if it differs from `certname`.

The Bolt plan `puppet::bootstrap` is available to automate the setup of Puppet agents on nodes. This plan performs the following tasks:

1. **Install Puppet Agent:**
   It uses the `puppet::agent::install` Bolt plan to install the Puppet agent on the target node.

2. **Configure Puppet:**
   It configures the `puppet.conf` file with the necessary settings, including the Puppet server name and, if provided, the `certname`.

3. **Run Bootstrap:**
   Finally, it runs the `puppet::agent::bootstrap` Bolt plan to initiate the Puppet agent bootstrap process, which handles certificate requests and private key creation.

## Limitations