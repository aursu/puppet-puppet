# Puppet bootstrap testing

## Start services

### Rocky Linux 8

```
docker-compose --project-directory $(pwd) -f tests/compose/rocky/8/docker-compose.yml up -d
```

### CentOS Stream 9

```
docker-compose --project-directory $(pwd) -f tests/compose/stream/9/docker-compose.yml up -d
```

### Ubuntu 20

```
docker-compose --project-directory $(pwd) -f tests/compose/ubuntu/20/docker-compose.yml up -d
```

### Ubuntu 22

```
docker-compose --project-directory $(pwd) -f tests/compose/ubuntu/22/docker-compose.yml up -d
```

## Run single service

In the Docker Compose setup, the `up` command is configured to start two containers simultaneously:
one for Puppet Server bootstrap testing and another for PuppetDB bootstrap testing. This
configuration ensures both essential components are operational for comprehensive testing
scenarios.

However, situations may arise requiring focus on a singular aspect of the environment, such as
conducting targeted testing on a single container for Puppet Server. For these instances, the `run`
command is recommended. This command facilitates the start of a specified service from the
`docker-compose.yml` file independently, allowing for the omission of other components. To execute
only the container designated for Puppet Server testing, the following command is advised:

```
docker-compose --project-directory $(pwd) -f tests/compose/rocky/8/docker-compose.yml run -d puppet
```

## Accessing containers for testing inside

To access a shell inside a container for testing purposes, use the `docker-compose exec` command
followed by the service name and the command you wish to execute. Here's an example for accessing a
bash shell inside a container based on the Rocky Linux 8 configuration:

```
docker-compose --project-directory $(pwd) -f tests/compose/rocky/8/docker-compose.yml exec puppet /bin/bash
```

To exit the shell session and return to your host machine, simply type `exit` or press `Ctrl+D`.
This command will terminate the shell session but will not stop the container itself.

## Stop services

To stop and remove all the related containers, networks, and volumes created by `up`, use the `down`
command. For example, to stop services for Rocky Linux 8:

```
docker-compose --project-directory $(pwd) -f tests/compose/rocky/8/docker-compose.yml down
```

Repeat the process with the appropriate file path for other services you wish to stop.

## Puppet Server Bootstrap in Docker Compose

### Puppet Server Bootstrap

In environments using Docker Compose, a service discovery mechanism allows for connecting to the
Puppet server Docker container via its container name or the service name defined in the
`docker-compose.yml` file. In this scenario, where the project folder name is `puppet-puppet`, the
container is automatically named `puppet-puppet-puppet-1`. Additionally, the predefined service name
within the Docker Compose file is `puppet`. To ensure seamless communication with the Puppet service
through these names, they must be included in the subject alternative names (SANs) of the Puppet
server's SSL certificate.

By default, the name `puppet` and the Fully Qualified Domain Name (FQDN) are automatically added to
the certificate's SANs by the `puppet::server::bootstrap` class. However, to include the container
name (e.g., `puppet-puppet-puppet-1`), it must be specified manually via the `dns_alt_names` parameter
when running the Bolt plan:

```
bolt plan run puppet_bootstrap::server -t puppetservers dns_alt_names=puppet-puppet-puppet-1
```

This approach ensures that all necessary names are recognized as valid identities of the Puppet
server, facilitating trusted connections within the Docker Compose network.

### PuppetDB Server Bootstrap

For the PuppetDB container to communicate using either the `puppetdb` name (as predefined in the
`docker-compose.yml` file) or the container name `puppet-puppet-puppetdb-1`, it's necessary to set
the PuppetDB container's `certname` to one of these names. This can be achieved by using the
`certname` CLI parameter when running the `puppet_bootstrap::puppetdb` Bolt plan. This action
configures the `certname` option within the `main` section of the `puppet.conf` file.

Furthermore, to enable PuppetDB to communicate with the Puppet server using the name
`puppet-puppet-puppet-1`, this name must be specified as the `puppet_server` parameter to the
`puppet_bootstrap::puppetdb` Bolt plan. Here's how you can run the Bolt plan with the necessary
parameters:

```
bolt plan run puppet_bootstrap::puppetdb -t puppetdb puppet_server=puppet-puppet-puppet-1 certname=puppet-puppet-puppetdb-1
```

This setup ensures that PuppetDB can establish a secure and recognized connection with the Puppet
server within the Docker Compose network, using the specified container and service names.

### Puppet Server Final Bootstrap

```
bolt plan run puppet_agent::run -t puppetservers environment=production
```