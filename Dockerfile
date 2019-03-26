FROM ubuntu:18.04

ARG MENDER_ARTIFACT_VERSION=2.3.0
ARG MENDER_CONVERT_VERSION=1.0.0
ARG GOLANG_VERSION=1.11.2

RUN apt-get update && apt-get install -y \
    kpartx \
    bison \
    flex \
    mtools \
    parted \
    mtd-utils \
    e2fsprogs \
    u-boot-tools \
    pigz \
    device-tree-compiler \
    autoconf \
    autotools-dev \
    libtool \
    pkg-config \
    python \
# for mender-convert to run (mkfs.vfat is required for boot partition)
    sudo \
    dosfstools \
# to compile U-Boot
    bc \
# to download mender-artifact
    wget \
# to download mender-convert and U-Boot sources
    git \
# To compile Mender client, U-boot or GRUB
    gcc-arm-linux-gnueabihf

# Disable sanity checks made by mtools. These checks reject copy/paste operations on converted disk images.
RUN echo "mtools_skip_check=1" >> $HOME/.mtoolsrc

RUN wget -q -O /usr/bin/mender-artifact https://d1b0l86ne08fsf.cloudfront.net/mender-artifact/$MENDER_ARTIFACT_VERSION/mender-artifact \
    && chmod +x /usr/bin/mender-artifact

# Golang environment, for cross-compiling the Mender client
RUN wget https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go$GOLANG_VERSION.linux-amd64.tar.gz \
    && echo export PATH=$PATH:/usr/local/go/bin >> /root/.bashrc

ARG mender_client_version

ENV MENDER_CLIENT_VERSION=$mender_client_version

# NOTE: we are assuming generic ARM board here, needs to be extended later

ENV PATH "$PATH:/usr/local/go/bin"
ENV GOPATH "/root/go"

RUN go get github.com/mendersoftware/mender
WORKDIR $GOPATH/src/github.com/mendersoftware/mender
RUN git checkout $MENDER_CLIENT_VERSION

RUN env CGO_ENABLED=1 \
    CC=arm-linux-gnueabihf-gcc \
    GOOS=linux \
    GOARCH=arm make build

RUN cp $GOPATH/src/github.com/mendersoftware/mender/mender /

WORKDIR /

COPY . /mender-convert/

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
