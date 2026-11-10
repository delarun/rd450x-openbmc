FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential chrpath cpio debianutils diffstat file gawk gcc g++ git \
    iputils-ping libacl1 liblz4-tool locales python3 python3-git python3-jinja2 \
    python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils \
    zstd ca-certificates sudo bzip2 lz4 rpcsvc-proto libsdl1.2-dev vim-tiny \
    qemu-system-arm device-tree-compiler \
 && rm -rf /var/lib/apt/lists/* \
 && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu 2>/dev/null; groupadd -g ${GID} builder && useradd -m -u ${UID} -g ${GID} -s /bin/bash builder
USER builder
WORKDIR /work
