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

### 3. Update r10k configuration file

   The `r10k.yaml` file, located in `modules/bootstrap_assets/files`, is pivotal for configuring the r10k tool to deploy Puppet environments. By default, it's set to deploy three environments: `production`, `common`, and `enc`. Customization of these environments requires forking the respective repositories and updating the configurations as follows:

   1. **For the `production` environment** (which can be forked from `https://github.com/aursu/control-init.git`):

      * Update SSH credentials in the Hiera configuration (`data/common.yaml` and `data/secrets.eyaml`) to access Git repositories of Puppet environments and privately hosted Puppet modules. These files are crucial for specifying access credentials (`profile::puppet::deploy::access` inside `data/secrets.eyaml`) and SSH configuration (`profile::puppet::deploy::ssh_config` inside `data/common.yaml`).
    
      * Additionally, these Hiera files can be configured with settings for PuppetDB (e.g., PostgreSQL database credentials) and parameters for Puppet server bootstrap (such as whether to install PuppetDB locally or on a separate server).

   2. **For the `common` repository** (which can be forked from `https://github.com/aursu/control-common.git`):

      * The `r10k::sources` parameter within the `data/global.yaml` Hiera configuration must be updated to reflect the production sources specific to your company or project.
    
      * The environment's `Puppetfile` should list all the Puppet server modules required across server types and environments, ensuring a common foundation for all setups.

   3. **For the `enc` repository** (which can be forked from `https://github.com/aursu/control-enc.git`):

      * It's recommended to update the predefined ENC configuration files for `puppet`, `puppetdb`, and `puppetserver` (where the file name corresponds to the certname) to the FQDN names of the actual hosts. At a minimum, the `puppet` ENC configuration file should be renamed to reflect the FQDN of the Puppet server being bootstrapped, ensuring accurate and functional environment-specific configurations.

### 4. Handle eYAML Keys

   If eYAML is used within your Puppet Bolt or bootstrap environment's Hiera, it's essential to manage the eYAML keys properly. Follow these guidelines based on your scenario:

   * **Using Existing Keys:** If you already have eYAML private and public keys, copy them into the `modules/bootstrap_assets/files/keys` directory. This ensures that your existing encrypted data can be seamlessly integrated and decrypted during the bootstrap process.

   * **Generating New Keys:** In the absence of existing keys, or if you're setting up a new environment that requires encrypted data handling, generate a new key pair. Utilize the instructions provided in the README file of the [Hiera eyaml](https://github.com/voxpupuli/hiera-eyaml) project. For example, you can generate new keys with the following command:

   ```
   /opt/puppetlabs/puppet/bin/eyaml createkeys \
      --pkcs7-private-key=modules/bootstrap_assets/files/keys/private_key.pkcs7.pem \
      --pkcs7-public-key=modules/bootstrap_assets/files/keys/public_key.pkcs7.pem
   ```

   This step is crucial for maintaining the integrity and security of your Puppet environment, ensuring that sensitive data remains encrypted and accessible only through proper decryption mechanisms.

### 5. Bootstrap Existing Puppet CA Certificate, Private Key, and CRL

   Bootstrapping (or importing) existing Puppet CA secure assets into a new environment is straightforward. Simply place the Puppet CA's private key (`ca_key.pem`), certificate (`ca_crt.pem`), and certificate revocation list (`ca_crl.pem`) into the `modules/bootstrap_assets/files/ca` directory.

   Puppet Bolt will then transfer these assets to the Puppet server, specifically to the default bootstrap folder for the Puppet CA, located at `/root/bootstrap/ca`. Following this transfer, the files will be imported into the new Puppet CA using the `puppetserver ca import` command. This process is facilitated by the `puppet::server::ca::import` Puppet class.

   See [Bootstrap assets description](bolt/modules/bootstrap_assets/README.md#setup-requirements) for details

### 6. Setup SSH Credentials for Git Repository Access

   Securing access to r10k tool repositories is essential, particularly when dealing with private repositories that contain proprietary settings and data unique to your organization. For managing SSH private keys, Puppet Bolt Hiera facilitates this through the configuration of the `puppet::server::bootstrap::access` parameter. This parameter accepts an array of SSH keys, ensuring controlled access based on your operational requirements.

   For example, to configure access to a GitHub repository, you can see example provided in the `secrets.eyaml` file within the [puppet-puppet repository (version 0.17.1)](https://github.com/aursu/puppet-puppet/blob/v0.17.1/bootstrap/bolt/data/secrets.eyaml#L5). Here's an illustrative snippet:

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

### 7. Update `gitservers.txt` with Git Server Hostnames

   The `gitservers.txt` file, located within `modules/bootstrap_assets/files`, plays a crucial role in establishing secure SSH connections. By listing the hostnames of your Git servers in this file, you enable the `ssh-keyscan` command to automatically update the `known_hosts` file for the root user. This process ensures that the SSH client recognizes and trusts your Git servers, facilitating seamless and secure Git operations.

## Bootstrap stages

### 1. The first and crucial stage involves installing the Puppet server in a basic setup using Puppet Bolt.

   This stage encompasses several key tasks:

   * Installing and starting the Puppet service on the node.
   * Setting up the Puppet Certificate Authority (CA).
   * Deploying bootstrap control repositories (Puppet environments) with the help of r10k, along with all necessary modules.
   * Propagating External Node Classifier (ENC) settings, which are especially useful in virtualized or on-premise servers, though less so in containerized environments.

   This basic installation of the Puppet server lays the groundwork for a full-scale bootstrap process. The subsequent step utilizes bootstrap Puppet control repositories and the Puppet agent, which is tasked with compiling a catalog containing the production settings for the Puppet server. This approach ensures a seamless transition from a basic setup to a fully configured production environment.

### 2. Next step depends on PuppetDB settings.
   
   The configuration of PuppetDB is crucial for the scalability and performance of your Puppet infrastructure, influenced by your specific architectural needs and operational requirements:

   * **PuppetDB on the Same Server as Puppet Server**: Best for smaller environments or where simplicity in deployment is prioritized. This consolidated management approach may limit scalability. For those selecting this configuration, the following step is straightforward: simply execute a Puppet agent run, which will automatically configure PuppetDB. This action completes the PuppetDB integration process.
    
   * **PuppetDB on a Separate Server**: Recommended for enhancing performance and scalability, particularly suited to larger environments poised for growth. This choice requires detailed planning for networking and security to facilitate seamless communication between the Puppet server and PuppetDB. **If opting for a separate PuppetDB server, the immediate next step involves bootstrapping the PuppetDB server using Puppet Bolt.** This process prepares the PuppetDB server for its role in the infrastructure. Once bootstrapped, it will be designated as the PuppetDB server during the final bootstrap phase of the Puppet server, ensuring a cohesive and efficient setup.
    
   * **Without PuppetDB**: For scenarios bypassing PuppetDB, resource management is directly handled by the Puppet master. This simplifies the infrastructure but restricts access to advanced features like exported resources and centralized fact storage.

   Choosing the optimal PuppetDB configuration is pivotal, with each option bringing its own set of considerations regarding system architecture, performance implications, and management practices.

### 3. Installing the Puppet Server for Full-Scale Production

   Transitioning to a full-scale production setup for the Puppet server involves executing a Puppet agent run. This process utilizes the settings predefined in the `production` bootstrap environment. It operates in one of two ways:

   1. **Using ENC Settings**: These settings assign the `stype` variable to the appropriate Puppet role, enabling the compilation of the Puppet catalog according to this specified role.

   2. **Applying the Default Role**: In the absence of specific ENC settings, the default role `role::puppet::master` is applied. The logic for this role assignment is detailed in the `manifests/site.pp` within the `production` environment. By default, this role establishes a single-host Puppet server configuration, which includes both PuppetDB and the Puppet CA on the same host.

   To configure a separate PuppetDB server, adjustments must be made within the `data/common.yaml` file in your Hiera configuration:

   ```
   profile::puppet::master::puppetdb_local: false
   profile::puppet::master::puppetdb_server: puppet-puppet-puppetdb-1
   ```

   An alternative approach involves applying the `role::puppet::server` role through ENC settings, using `stype: puppet::server`. This approach, while echoing the need for specifying a separate PuppetDB server in Hiera, introduces the possibility to exclude the Puppet CA setup on the host. To configure an external Puppet CA and designate a separate PuppetDB server, the Hiera configuration should be updated as follows:

   ```
   profile::puppet::server::sameca: false
   profile::puppet::server::ca_server: puppet-puppet-puppet-1
   profile::puppet::server::puppetdb_server: puppet-puppet-puppetdb-1
   ```

   All the aforementioned Hiera settings can also be defined within the Hiera configuration files located in the Puppet Bolt project directory. The relevant paths for these configurations are `modules/bootstrap_assets/files/hiera/common.yaml` for standard settings and `modules/bootstrap_assets/files/hiera/secrets.eyaml` for encrypted values.

   When running Puppet Bolt, it automatically uploads these configurations into the `production` environment, specifically to `data/common.yaml` and `data/secrets.eyaml`, effectively replacing the existing files. This mechanism ensures that your `production` environment is configured with the precise settings defined in your Puppet Bolt project, streamlining the setup process.

## Bootstrap process

1. **Installing the Puppet server in a basic setup:**

   Begin by installing and configuring a basic Puppet server setup. Use the following command to run the Puppet Bolt plan, specifying any DNS alternative names as needed:

   ```
   bolt plan run puppet_bootstrap::server -t puppetservers dns_alt_names=puppet-puppet-puppet-1
   ```

   2. **Bootstrapping the PuppetDB Server Using Puppet Bolt**

   Once the Puppet server is up, the next step involves setting up the PuppetDB server. This step is critical for managing and storing your configuration data effectively. Execute the following command to bootstrap PuppetDB, specifying the Puppet server and the desired certificate name:

   ```
   bolt plan run puppet_bootstrap::puppetdb -t puppetdb \
      puppet_server=puppet-puppet-puppet-1 \
      certname=puppet-puppet-puppetdb-1
   ```

   3. **Installing the Puppet Server for Full-Scale Production**

   With the basic setup of the Puppet server and PuppetDB complete, the next step is to install the Puppet server for a full-scale production environment. This involves running the Puppet agent in the production environment to apply all configurations and settings:

   ```
   bolt plan run puppet_agent::run -t puppetservers environment=production
   ```
