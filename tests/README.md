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

## Puppet Server bootstrap

```
bolt plan run puppet_bootstrap::server -t puppetservers dns_alt_names=puppet-puppet-puppet-1
```

### PuppetDB sserver bootstrap

```
bolt plan run puppet::bootstrap -t puppetdb server=puppet-puppet-puppet-1
bolt plan run puppet::cert::sign -t puppetdb server=puppet-puppet-puppet-1
bolt plan run puppet::bootstrap -t puppetdb server=puppet-puppet-puppet-1
bolt plan run puppet_bootstrap::puppetdb -t puppetdb
```