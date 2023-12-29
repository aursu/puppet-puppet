ARG os=jammy-20230816

FROM ubuntu:${os}

ARG codename=jammy
ARG platform=puppet7

ENV PATH=/opt/puppetlabs/puppet/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y \
        g++ \
        git \
        make \
        wget \
        ruby ruby-dev \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://apt.puppet.com/${platform}-release-${codename}.deb && dpkg -i ${platform}-release-${codename}.deb \
    && apt-get update && apt-get install -y \
        puppet-agent \
    && rm -rf /var/lib/apt/lists/*

RUN echo 'export PATH=/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:$PATH' >> ~/.bashrc

RUN puppet module install puppetlabs-inifile --version 5.4.1 \
    && puppet module install puppetlabs-puppetdb \
    && puppet module install puppetlabs-puppet_agent \
    && puppet module install puppet-r10k \
    && puppet module install aursu-lsys_postgresql \
    && puppet module install aursu-openssh

COPY . /etc/puppetlabs/code/environments/production/modules/puppet
WORKDIR /etc/puppetlabs/code/environments/production/modules/puppet/bootstrap
