FROM debian:8
MAINTAINER wraithfive
ENV LANG C.UTF-8
#
# Create user and group for SABnzbd.
#

RUN groupadd -r -g 666 sabnzbd \
    && useradd -r -u 666 -g 666 -d /sabnzbd sabnzbd

#
# Add SABnzbd init script.
#

ADD sabnzbd.sh /sabnzbd.sh
RUN chmod 755 /sabnzbd.sh

#
# Install SABnzbd and all required dependencies.
#

RUN export SABNZBD_VERSION=2.2.0RC1 PAR2CMDLINE_VERSION=v0.6.14-mt1 \
    && sed -i "s/ main$/ main contrib non-free/" /etc/apt/sources.list \
    && apt-get -q update \
    && apt-get install -qy curl ca-certificates python-cheetah python-openssl python-yenc python-dev python-pip unzip unrar p7zip-full build-essential automake \
    && pip install sabyenc --upgrade \
    && curl -L -o /tmp/sabnzbd.tar.gz https://github.com/sabnzbd/sabnzbd/releases/download/${SABNZBD_VERSION}/SABnzbd-${SABNZBD_VERSION}-src.tar.gz \
    && tar xzf /tmp/sabnzbd.tar.gz \
    && mv SABnzbd-* sabnzbd \
    && chown -R sabnzbd: sabnzbd \
    && curl -L -o /tmp/par2cmdline.tar.gz https://codeload.github.com/jkansanen/par2cmdline-mt/tar.gz/${PAR2CMDLINE_VERSION} \
    && tar xzf /tmp/par2cmdline.tar.gz -C /tmp \
    && cd /tmp/par2cmdline-* \
    && aclocal \
    && automake --add-missing \
    && autoconf \
    && ./configure \
    && make \
    && make install \
    && apt-get -y remove curl build-essential automake \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && cd / \
    && rm -rf /tmp/*

#
# Define container settings.
#

VOLUME ["/datadir", "/media", "/backup", "/watched"]

EXPOSE 8080

#
# Start SABnzbd.
#

WORKDIR /sabnzbd

CMD ["/sabnzbd.sh"]
