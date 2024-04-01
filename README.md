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

Module could be used as regural Puppet module (eg in Puppetfile):

```
mod 'puppet',
  git: 'https://github.com/aursu/puppet-puppet.git',
  tag: 'v0.14.0'
```

or

```
mod 'aursu/puppet', '0.14.0'
```

But also it could be used as Puppet server bootstrap tool using Puppet Bolt. It
contains Bolt plan to bootstrap puppet server `puppet_bootstrap::server`:

```
bolt plan run puppet_bootstrap::server -t puppetservers
bolt plan run puppet_agent::run -t puppetservers environment=production
```

### What `puppet` affects **OPTIONAL**

### Setup Requirements **OPTIONAL**

### Beginning with `puppet`

## Usage

## Limitations