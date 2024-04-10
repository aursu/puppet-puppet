ARG osrepo=aursu/centos
ARG os=stream9-20230605.0

FROM ${osrepo}:${os}-systemd

ARG codename=el
ARG osmajor=9
ARG platform=puppet8

ENV PATH=/opt/puppetlabs/puppet/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /root

# tools for troubleshooting within container
RUN microdnf -y install \
        diffutils \
        dnf \
        iproute \
        iputils \
        procps-ng \
        tar \
        tzdata \
        vim \
    && microdnf clean all && rm -rf /var/cache/dnf /var/lib/rpm/__db*

# We need Puppet Bolt, OpenSSH server and crontab to proceed with Puppet server
# bootstrap inside container
RUN rpm -Uvh https://yum.puppet.com/${platform}-release-${codename}-${osmajor}.noarch.rpm \
    && dnf -y install \
        puppet-bolt \
        openssh-server \
        cronie \
    && dnf clean all && rm -rf /var/cache/dnf /var/lib/rpm/__db*

# Setup SSH server
COPY tests/redhat/sshd/sshd_config /etc/ssh/sshd_config
COPY --chmod=600 tests/redhat/sshd/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
COPY --chmod=640 tests/redhat/sshd/known_hosts /root/.ssh/known_hosts

RUN ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N '' <<<y \
    && cp -a .ssh/id_ed25519.pub .ssh/authorized_keys

RUN cp /etc/skel/.bash_profile /etc/skel/.bashrc ~/ \
    && echo 'export PATH=/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:$PATH' >> ~/.bashrc

RUN mkdir -p /var/tmp && chmod 1777 /var/tmp

# CentOS 9 timezone fix
RUN ln -sf ../usr/share/zoneinfo/Europe/Berlin /etc/localtime

COPY . /root/bootstrap/puppet
WORKDIR /root/bootstrap/puppet/bootstrap/bolt

# Setup Puppet Bolt modules
RUN bolt module install --force