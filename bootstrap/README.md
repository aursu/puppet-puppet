# Puppet Server bootstrap

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
