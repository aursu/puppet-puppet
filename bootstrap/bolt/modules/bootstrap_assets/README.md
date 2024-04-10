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

### Setup Requirements

If an existing Puppet server with Puppet CA is already in place, you can back up the current keys
using the following command:

```
tar czf keys.tar.gz -C /etc/puppetlabs puppetserver/ca/ca_key.pem puppetserver/ca/ca_crt.pem puppetserver/ca/ca_crl.pem puppetserver/ca/serial puppet/keys/private_key.pkcs7.pem puppet/keys/public_key.pkcs7.pem
```

This command consolidates the essential CA keys and certificates into a single archive (`keys.tar.gz`),
simplifying the process of securing and transferring these critical components.

This archive can then be downloaded into your Bolt project and unpacked for the bootstrap of these
components on a new Puppet server with the following commands:

```
tar zxf keys.tar.gz -C modules/bootstrap_assets/files/ --strip-components=1 puppetserver/ca
tar zxf keys.tar.gz -C modules/bootstrap_assets/files/ --strip-components=1 puppet/keys
```

These steps ensure a seamless migration or duplication of essential security components to a new
Puppet server setup, preserving the integrity of your Puppet infrastructure's security.

### Beginning with bootstrap_assets

The `bootstrap_assets` Puppet module is designed to store essential bootstrap assets required for
the initial setup process. Among these assets, you will find:

* `files/gitservers.txt` - This file contains a list of Git server addresses. It is used by the
Puppet server to execute the `ssh-keyscan -f gitservers.txt` command. This process retrieves the
SSH host keys from the listed Git servers and stores them in the `known_hosts` file for the
system's root account, ensuring secure SSH connections without manual host key verification.
* `files/r10k.yaml` - This configuration file outlines the Puppet environments utilized during the
bootstrap process of the Puppet server. Currently, it includes two environments: `production` and
`common`. These environments are configured with specific profiles that are sufficient for setting
up the Puppet server, PuppetDB with PostgreSQL, and r10k.
* `keys/private_key.pkcs7.pem` - This is the eYAML private key used by the Puppet server to decrypt
encrypted values within Hiera.
* `keys/public_key.pkcs7.pem` - This file is the eYAML public key corresponding to the private key.
* `ca/ca_key.pem` - This file contains the private key for the Puppet Certificate Authority (CA)
and may be used to initialize the CA during the bootstrap process of a new Puppet server. While
not mandatory, using this key is beneficial for the establishment of a CA already existing within
the current Puppet infrastructure.
* `ca/ca_crt.pem` - This file contains the Certificate Authority (CA) certificate, directly
corresponding to the private key found in `ca/ca_key.pem`. It is instrumental in establishing a
trusted communication channel within the Puppet environment. The CA certificate facilitates the
verification of authenticity between the Puppet server and its nodes, ensuring all interactions are
securely encrypted and trusted.
* `ca/ca_crl.pem` - This file holds the Certificate Revocation List (CRL), which is essential for
maintaining the integrity of the CA's trust network. It lists all certificates that have been
revoked and are no longer considered valid. By referencing this list, the Puppet server can prevent
compromised or unauthorized certificates from being used, thereby safeguarding the security of
communications within the Puppet infrastructure.
* `hiera/common.yaml` - This file serves as the Hiera configuration intended to replace the
identical configuration within the already deployed `production` environment during the bootstrap
process. This adjustment allows for real-time modifications to the bootstrap process using
Puppet Bolt.
* `hiera/secrets.eyaml` - Similar to `hiera/common.yaml`, but it also supports eYAML encrypted
values. The encryption relies on the keys located at `keys/private_key.pkcs7.pem`
and `keys/public_key.pkcs7.pem` mentioned above. This feature enables the secure handling of
sensitive data within the configuration.

## Usage

## Limitations
