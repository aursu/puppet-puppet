ARG os=jammy-20230816
FROM ubuntu:${os}

ARG codename=jammy
ARG platform=puppet8

ENV PATH=/opt/puppetlabs/puppet/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG=C

RUN apt-get update && apt-get install -y \
        curl \
        g++ \
        git \
        iproute2 \
        iputils-ping \
        make \
        ruby ruby-dev \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://apt.puppet.com/${platform}-release-${codename}.deb && dpkg -i ${platform}-release-${codename}.deb \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        puppet-bolt \
        openssh-server \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY tests/ubuntu/sshd/sshd_config /etc/ssh/sshd_config
COPY --chmod=600 tests/redhat/sshd/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
COPY --chmod=640 tests/redhat/sshd/known_hosts /root/.ssh/known_hosts

WORKDIR /root

RUN bash -c "ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N '' <<<y" \
    && cp -a .ssh/id_ed25519.pub .ssh/authorized_keys

RUN echo 'export PATH=/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:$PATH' >> ~/.bashrc
RUN echo 'export LANG=C' >> ~/.bashrc

RUN mkdir -p /var/tmp && chmod 1777 /var/tmp

COPY . /root/bootstrap/puppet
WORKDIR /root/bootstrap/puppet/bootstrap/bolt

# Setup Puppet Bolt modules
RUN bolt module install --force

CMD ["/usr/sbin/init"]
