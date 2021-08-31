FROM ubuntu:latest

# This container is based on https://github.com/apluslms/grading-base
#   * instead of debian:buster-slim the ubuntu:latest is used
#   * python3.8 and pip3 are installed
#   * Qt 6.1.1 is installed using the aqtinstall tool https://github.com/miurahr/aqtinstall

ENV QT_VERSION v6.1.1

ENV LANG=C.UTF-8 USER=root HOME=/root

# Tools for dockerfiles and image management
COPY rootfs /

RUN apt-get -y upgrade
RUN apt-get -y update

RUN apt-get -y install software-properties-common apt-utils

RUN add-apt-repository main
RUN add-apt-repository universe
RUN add-apt-repository restricted
RUN add-apt-repository multiverse

RUN apt-get -y upgrade
RUN apt-get -y update

#RUN apt-get -y install apt-transport-https

RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get -y install python3.8 python3-pip

RUN apt_install \
	  runit \
	  ca-certificates \
	  curl \
	  gnupg dirmngr \
	  jo \
	  jq \
	  time \
	  git \
	  openssh-client \
	  python3-requests \
	  wget \
	  xz-utils \
	  make \
	  g++ \
    libgl1-mesa-dev \
  && rm -rf /root/.cache \
  && cp /usr/bin/chpst /usr/local/bin \
  && dpkg -P runit \
  && (cd /usr/local/bin && ln -s chpst setuidgid && ln -s chpst softlimit && ln -s chpst setlock)

RUN python3.8 -m pip install --upgrade pip
RUN pip3 install pexpect

# https://github.com/miurahr/aqtinstall
RUN pip3 install aqtinstall

RUN useradd -G video -ms /bin/bash user

RUN mkdir -p /usr/local/Qt

WORKDIR /tmp

ENV QT_VERSION v6.1.1

ARG QT=6.1.1

RUN aqt install --outputdir /usr/local/Qt ${QT} linux desktop gcc_64

RUN ln -s /usr/local/Qt/${QT}/gcc_64/bin/qmake /usr/bin/qmake

# https://github.com/miurahr/aqtinstall#environment-variables
ENV PATH /usr/local/Qt/${QT}/gcc_64/bin:$PATH
ENV QT_PLUGIN_PATH /usr/local/Qt/${QT}/gcc_64/plugins/
ENV QML_IMPORT_PATH /usr/local/Qt/${QT}/gcc_64/qml/
ENV QML2_IMPORT_PATH /usr/local/Qt/${QT}/gcc_64/qml/

RUN rm -r /tmp/* \
  && mkdir -p /feedback /submission /exercise \
  && chmod 0770 /feedback \
  && usermod -d /tmp nobody

# Base grading tools
COPY bin /usr/local/bin

#This is a semi hack for a Qt error regarding Qt libraries and Linux system calls in kernel which can't be handled
#https://askubuntu.com/questions/1034313/ubuntu-18-4-libqt5core-so-5-cannot-open-shared-object-file-no-such-file-or-dir
RUN strip --remove-section=.note.ABI-tag /usr/local/Qt/6.1.1/gcc_64/lib/libQt6Core.so.6

WORKDIR /submission
CMD ["bash"]
