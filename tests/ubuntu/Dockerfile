ARG os=jammy-20230816

FROM ubuntu:${os}

ARG codename=jammy
ARG platform=puppet7

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
