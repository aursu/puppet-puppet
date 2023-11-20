ARG osrepo=aursu/centos
ARG os=stream9-20230605.0

FROM ${osrepo}:${os}-systemd

ARG codename=el
ARG osmajor=9
ARG platform=puppet7

ENV PATH=/opt/puppetlabs/puppet/bin::/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN microdnf -y install \
        diffutils \
        dnf \
        tar \
        vim \
    && microdnf clean all && rm -rf /var/cache/dnf /var/lib/rpm/__db*

RUN rpm -Uvh https://yum.puppet.com/${platform}-release-${codename}-${osmajor}.noarch.rpm \
    && dnf -y install puppet-agent \
    && dnf clean all && rm -rf /var/cache/dnf /var/lib/rpm/__db*
