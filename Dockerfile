# PetaLinux 2023 depends on Ubuntu 22.04
# PetaLinux 2022 depends on Ubuntu 20.04
# PetaLinux 2020 depends on Ubuntu 20.04

ARG UBUNTU_VERSION
FROM ubuntu:${UBUNTU_VERSION}

ARG UBUNTU_VERSION
ARG PETA_RUN_FILE
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Example:
# docker build \
#   --build-arg UBUNTU_VERSION=20.04 \
#   --build-arg PETA_RUN_FILE=petalinux-v2020.2-final-installer.run \
#   -t petalinux:2020.2 .

# Install dependencies
RUN apt-get update && \
    apt-get install -y -q \
      autoconf \
      bash \
      bc \
      bison \
      build-essential \
      chrpath \
      cpio \
      curl \
      diffstat \
      expect \
      flex \
      gawk \
      gcc-multilib \
      git \
      gnupg \
      gzip \
      iproute2 \
      kmod \
      libglib2.0-dev \
      libgtk2.0-0 \
      libncurses5-dev \
      libselinux1 \
      libssl-dev \
      libsdl1.2-dev \
      libtool \
      libtool-bin \
      libtinfo5 \
      locales \
      lsb-release \
      net-tools \
      pax \
      python3 \
      rsync \
      screen \
      socat \
      sudo \
      texinfo \
      tftpd \
      tofrodos \
      u-boot-tools \
      unzip \
      update-inetd \
      vim \
      wget \
      xterm \
      xvfb \
      xxd \
      zip \
      lib32z1-dev && \
    . /etc/os-release && \
    if [[ "${VERSION_ID}" == "20.04" || "${VERSION_ID}" == "18.04" ]]; then \
      apt-get install -y libidn11; \
    else \
      apt-get install -y libidn12; \
    fi && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y -q zlib1g:i386 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Make /bin/sh point to bash before PetaLinux install
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Optional AWS CLI for S3-backed sstate/artifact use
WORKDIR /tmp
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Create non-root build user
RUN adduser --disabled-password --gecos '' vivado && \
    usermod -aG sudo vivado && \
    usermod --shell /bin/bash vivado && \
    echo "vivado ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

COPY accept-eula.sh ${PETA_RUN_FILE} /

# Install PetaLinux as non-root user
RUN mkdir -p /opt/Xilinx && \
    chown -R vivado:vivado /opt/Xilinx && \
    chmod 1777 /tmp && \
    chmod a+rx /${PETA_RUN_FILE} /accept-eula.sh && \
    cd /tmp && \
    su - vivado -c "/accept-eula.sh /${PETA_RUN_FILE} /opt/Xilinx/petalinux" && \
    rm -f /${PETA_RUN_FILE} /accept-eula.sh

USER vivado
ENV HOME=/home/vivado
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN mkdir -p /home/vivado/project
WORKDIR /home/vivado/project

RUN echo "source /opt/Xilinx/petalinux/settings.sh" >> /home/vivado/.bashrc