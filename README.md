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
    tag: 'v0.19.0'
  ```

  Alternatively, you can specify the version directly if it’s available from the module repository on [Puppet Forge](https://forge.puppet.com/modules/aursu/puppet/readme):

  ```
  mod 'aursu/puppet', '0.14.0'
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

### What `puppet` affects **OPTIONAL**

### Setup Requirements **OPTIONAL**

### Beginning with `puppet`

## Usage

## Limitations