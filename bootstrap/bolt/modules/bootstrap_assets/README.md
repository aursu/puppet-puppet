# bootstrap_assets

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with bootstrap_assets](#setup)
    * [What bootstrap_assets affects](#what-bootstrap_assets-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with bootstrap_assets](#beginning-with-bootstrap_assets)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

Puppet module to store bootstrap assets in order to have ability to deploy them 
using [Puppet Bolt](https://www.puppet.com/community/open-source/bolt)

## Setup

### What bootstrap_assets affects **OPTIONAL**

### Setup Requirements **OPTIONAL**

### Beginning with bootstrap_assets

The `bootstrap_assets` Puppet module is designed to store essential bootstrap assets required for
the initial setup process. Among these assets, you will find:

* `files/gitservers.txt` - This file contains a list of Git server addresses. It is used by the
Puppet server to execute the `ssh-keyscan -f gitservers.txt` command. This process retrieves the
SSH host keys from the listed Git servers and stores them in the `known_hosts` file for the
system's root account, ensuring secure SSH connections without manual host key verification.

## Usage

## Limitations
