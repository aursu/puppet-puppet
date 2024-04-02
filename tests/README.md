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

## Stop services

To stop and remove all the related containers, networks, and volumes created by `up`, use the `down`
command. For example, to stop services for Rocky Linux 8:

```
docker-compose --project-directory $(pwd) -f tests/compose/rocky/8/docker-compose.yml down
```

Repeat the process with the appropriate file path for other services you wish to stop.