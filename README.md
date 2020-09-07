
# puppet

1) rpm -Uvh https://yum.puppet.com/puppet5-release-el-7.noarch.rpm
2) yum -y install puppet-agent

#### bootstrap
3) echo -e "[main]\nserver = <puppet server FQDN>" >> /etc/puppetlabs/puppet/puppet.conf

#### in case if not first installation
4) find /etc/puppetlabs/puppet/ -name "*$(hostname)*" -delete
5) /opt/puppetlabs/bin/puppet agent --test

### See REFERENCE.md for some details