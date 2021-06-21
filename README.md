
# puppet

#### install

1) Enable the Puppet platform repository
```
rpm -Uvh https://yum.puppet.com/puppet7-release-el-8.noarch.rpm
```
2) Install Puppet agent
```
yum -y install puppet-agent
```

#### bootstrap

3) Set the primary server `<puppet server FQDN>` to request configurations from
```
echo -e "[main]\nserver = <puppet server FQDN>" >> /etc/puppetlabs/puppet/puppet.conf
```

#### in case if this is not first installation

4) find /etc/puppetlabs/puppet/ -name "*$(hostname)*" -delete
5) /opt/puppetlabs/bin/puppet agent --test

### See REFERENCE.md for some details