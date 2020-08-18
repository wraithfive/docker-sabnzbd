FROM python:3.7-slim-buster
MAINTAINER wraithfive

#
# Add SABnzbd init script.
#

ADD sabnzbd.sh /sabnzbd.sh

#
# Fix locales to handle UTF-8 characters.
#

ENV LANG C.UTF-8

#
# Specify versions of software to install.
#
ARG SABNZBD_VERSION=3.0.1

#
# Install SABnzbd and all required dependencies.
#
RUN export DEBIAN_FRONTEND=noninteractive &&\
    groupadd -r -g 666 sabnzbd &&\
    useradd -l -r -u 666 -g 666 -d /sabnzbd sabnzbd &&\
    chmod 755 /sabnzbd.sh &&\
    sed -i "s#deb http://deb.debian.org/debian buster main#deb http://deb.debian.org/debian buster main non-free#g" /etc/apt/sources.list &&\
    apt-get -q update &&\
    apt-get install -qqy build-essential python3-cheetah python3-cryptography par2 unrar p7zip-full unzip openssl python3-openssl ca-certificates curl &&\
    pip install --no-cache-dir sabyenc &&\
    curl -SL -o /tmp/sabnzbd.tar.gz https://github.com/sabnzbd/sabnzbd/releases/download/${SABNZBD_VERSION}/SABnzbd-${SABNZBD_VERSION}-src.tar.gz &&\
    tar xzf /tmp/sabnzbd.tar.gz &&\
    mv SABnzbd-* sabnzbd &&\
    chown -R sabnzbd: sabnzbd &&\
    apt-get -y remove --purge curl build-essential &&\
    apt-get -y autoremove &&\
    rm -rf /var/lib/apt/lists/* &&\
    rm -rf /tmp/*

#
# Define container settings.
#

VOLUME ["/datadir", "/media"]

EXPOSE 8080

#
# Start SABnzbd.
#

WORKDIR /sabnzbd

CMD ["/sabnzbd.sh"]
