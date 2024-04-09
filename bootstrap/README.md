# Puppet Server bootstrap

## Initialization

To kickstart the bootstrap process, follow these essential preliminary steps:

### 1. Clone the Puppet module repository

   Execute the command below to clone the repository. This repository contains the necessary Puppet modules for the bootstrap process.

   ```
   git clone https://github.com/aursu/puppet-puppet.git
   ```

### 2. Change the working directory

   Navigate to the bootstrap directory within the cloned repository by changing your working directory.

   ```
   cd puppet-puppet/bootstrap/bolt
   ```

### 3. Handle eYAML Keys

   If eYAML is used within your Puppet Bolt or bootstrap environment's Hiera, it's essential to manage the eYAML keys properly. Follow these guidelines based on your scenario:

   * **Using Existing Keys:** If you already have eYAML private and public keys, copy them into the `modules/bootstrap_assets/files/keys` directory. This ensures that your existing encrypted data can be seamlessly integrated and decrypted during the bootstrap process.

   * **Generating New Keys:** In the absence of existing keys, or if you're setting up a new environment that requires encrypted data handling, generate a new key pair. Utilize the instructions provided in the README file of the [Hiera eyaml](https://github.com/voxpupuli/hiera-eyaml) project. For example, you can generate new keys with the following command:

   ```
   /opt/puppetlabs/puppet/bin/eyaml createkeys \
      --pkcs7-private-key=modules/bootstrap_assets/files/keys/private_key.pkcs7.pem \
      --pkcs7-public-key=modules/bootstrap_assets/files/keys/public_key.pkcs7.pem
   ```

   This step is crucial for maintaining the integrity and security of your Puppet environment, ensuring that sensitive data remains encrypted and accessible only through proper decryption mechanisms.

### 4. Setup SSH Credentials for Git Repository Access:
   Securing access to r10k tool repositories is essential, particularly when dealing with private repositories that contain proprietary settings and data unique to your organization. For managing SSH private keys, Puppet Bolt Hiera facilitates this through the configuration of the `puppet::server::bootstrap::access` parameter. This parameter accepts an array of SSH keys, ensuring controlled access based on your operational requirements.

   For example, to configure access to a GitHub repository, you can see example provided in the `secrets.eyaml` file within the [puppet-puppet repository (version 0.16.0)](https://github.com/aursu/puppet-puppet/blob/v0.16.0/bootstrap/bolt/data/secrets.eyaml#L5). Here's an illustrative snippet:

   ```
   # The `key_data` field contains the eYAML encrypted SSH private key, compacted to preserve formatting.
   puppet::server::bootstrap::access:
     - name: github.com-aursu-control-init
       key_prefix: control-init
       key_data: ENC[PKCS7,MII...75A==]
       ssh_options:
         HostName: github.com
   ```

   Additionally, it's feasible to utilize the same SSH key across various repository hosts, e.g. BitBucket, corporate GitLab, and GitHub. To accomplish this, alongside configuring SSH credentials as previously described, it’s essential to set up another Hiera parameter,  `profile::puppet::deploy::ssh_config`. This parameter allows for the specification of additional SSH client configurations, ensuring smooth access across different platforms with a unified SSH key.

   Here’s how you can configure the SSH access and client options for multiple hosts:

   ```
   puppet::server::bootstrap::access:
     - name: bitbucket.org
       server: github.com-aursu-control-init
       key_prefix: bitb
       key_data: ENC[PKCS7,MII...wFm]
       sshkey_type: rsa
       ssh_options:
         HostName: github.com

   profile::puppet::deploy::ssh_config:
     - Host: ['bitbucket.org', 'gitlab.company.tld']
       StrictHostKeyChecking: 'no'
       IdentityFile: '~/.ssh/bitb.id_rsa'
   ```

   Puppet Bolt Hiera configurations are managed within the `data/secrets.eyaml` file for encrypted values, and the `data/common.yaml` file for all other values.

### 5. Bootstrap Existing Puppet CA Certificate, Private Key, and CRL

   Bootstrapping (or importing) existing Puppet CA secure assets into a new environment is straightforward. Simply place the Puppet CA's private key (`ca_key.pem`), certificate (`ca_crt.pem`), and certificate revocation list (`ca_crl.pem`) into the `modules/bootstrap_assets/files/ca` directory.

   Puppet Bolt will then transfer these assets to the Puppet server, specifically to the default bootstrap folder for the Puppet CA, located at `/root/bootstrap/ca`. Following this transfer, the files will be imported into the new Puppet CA using the `puppetserver ca import` command. This process is facilitated by the `puppet::server::ca::import` Puppet class.

   See [Bootstrap assets description](bolt/modules/bootstrap_assets/README.md#setup-requirements) for details

## Bootstrap stages

1. The first and crucial stage involves installing the Puppet server in a basic setup using Puppet Bolt. This stage encompasses several key tasks:
   * Installing and starting the Puppet service on the node.
   * Setting up the Puppet Certificate Authority (CA).
   * Deploying bootstrap control repositories (Puppet environments) with the help of r10k, along with all necessary modules.
   * Propagating External Node Classifier (ENC) settings, which are especially useful in virtualized or on-premise servers, though less so in containerized environments.

   This basic installation of the Puppet server lays the groundwork for a full-scale bootstrap process. The subsequent step utilizes bootstrap Puppet control repositories and the Puppet agent, which is tasked with compiling a catalog containing the production settings for the Puppet server. This approach ensures a seamless transition from a basic setup to a fully configured production environment.

2. Next step depends on PuppetDB settings. There are few possibilities:
   * PuppetDB resides on the same server as Puppet server itself
   * PuppetDB resides on separate server
   * PuppetDB is not in use
