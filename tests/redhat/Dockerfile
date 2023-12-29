ARG osrepo=aursu/centos
ARG os=stream9-20230605.0

FROM ${osrepo}:${os}-systemd

ARG codename=el
ARG osmajor=9
ARG platform=puppet7

ENV PATH=/opt/puppetlabs/puppet/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN microdnf -y install \
        diffutils \
        dnf \
        tar \
        vim \
    && microdnf clean all && rm -rf /var/cache/dnf /var/lib/rpm/__db*

RUN rpm -Uvh https://yum.puppet.com/${platform}-release-${codename}-${osmajor}.noarch.rpm \
    && dnf -y install puppet-agent \
    && dnf clean all && rm -rf /var/cache/dnf /var/lib/rpm/__db*

RUN cp /etc/skel/.bash_profile /etc/skel/.bashrc ~/ \
    && echo 'export PATH=/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:$PATH' >> ~/.bashrc

RUN puppet module install puppetlabs-inifile --version 5.4.1 \
    && puppet module install puppetlabs-puppetdb \
    && puppet module install puppetlabs-puppet_agent \
    && puppet module install puppet-r10k \
    && puppet module install aursu-lsys_postgresql \
    && puppet module install aursu-openssh

COPY . /etc/puppetlabs/code/environments/production/modules/puppet
WORKDIR /etc/puppetlabs/code/environments/production/modules/puppet/bootstrap