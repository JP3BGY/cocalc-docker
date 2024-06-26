##########################################################################################
#
# This is a version of cocalc-docker running in **personal mode**, which is meant for
# development, personal use, or when you do not need any security features provided by
# cocalc itself, and can instead rely on whatever is running Docker containers.
#
# This removes *all* of the internal cocalc-docker security and isolation functionality;
# in particular, there's no authentication, SSL, etc.
# This does not need root at all to run anything, so you can run it in "rootless" mode,
# where the Docker doesn't allow becoming the root user in this container.
# But you must provide your own security, e.g., firewall this container in some way.
# This could be useful in a Kubernetes cluster, where you can easily isolate pods to
# only receive incoming connections from designated other pods.
# This could also be useful if you want a quick way to run cocalc on your laptop,
# and hence don't require any security or isolation (but be sure your container is
# only listening on localhost).
#
# This container starts cocalc listening via http on port 5000.
#
# To make cocalc appear on port 5123 on your laptop on localhost only (so not exposed to the world):
#
#   docker run --name=cocalc-test-personal -d -v ~/cocalc-test-personal:/home/user/cocalc/src/data -p 127.0.0.1:5123:5000 sagemathinc/cocalc-personal
#
# The above also stores all persistent data in ~/cocalc-test-personal on your computer.
# Omit that if you want to use the container in a purely ephemeral way.
#
# Also, the log files are in /home/user/logs/.
#
# Any user this cocalc can also do "sudo su" to become root... if docker isn't running the
# container in rootless mode.
#
##########################################################################################

ARG MYAPP_IMAGE=ubuntu:24.04
FROM $MYAPP_IMAGE

MAINTAINER William Stein <wstein@sagemath.com>

USER root

# See https://github.com/sagemathinc/cocalc/issues/921
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV TERM screen


# So we can source (see http://goo.gl/oBPi5G)
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Ubuntu software that are used by CoCalc
RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       software-properties-common \
       tmux \
       flex \
       bison \
       libreadline-dev \
       poppler-utils \
       net-tools \
       wget \
       curl \
       git \
       python3 \
       python-is-python3 \
       python3-pip \
       make \
       g++ \
       sudo \
       psmisc \
       rsync \
       tidy \
       vim \
       inetutils-ping \
       lynx \
       telnet \
       git \
       ssh \
       m4 \
       latexmk \
       libpq5 \
       libpq-dev \
       build-essential \
       automake \
       jq \
       postgresql \
       bsdmainutils \
       libfuse-dev \
       pkg-config \
       lz4

# Install node v18.17.1
# CRITICAL:  Do *NOT* upgrade nodejs to a newer version until the following is fixed !!!!!!
#    https://github.com/sagemathinc/cocalc/issues/6963
# Also, below I got 18.17.1-1nodesource1 by looking at the output of 'apt-cache showpkg nodejs|grep 18.17'
RUN  apt-get update \
  && apt-get remove -y nodejs libnode72 nodejs-doc \
  && apt-get install -y ca-certificates curl gnupg \
  && mkdir -p /etc/apt/keyrings \
  && rm -f /etc/apt/keyrings/nodesource.gpg  \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && export NODE_MAJOR=18 \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt-get update && apt-get install nodejs=18.17.1-1nodesource1 -y \
  && apt-mark hold nodejs

# Install pnpm package manager that we now use instead of npm
RUN umask 022 && npm install -g pnpm

RUN echo "umask 077" >> /etc/bash.bashrc

# Build a UTF-8 locale, so that tmux works -- see https://unix.stackexchange.com/questions/277909/updated-my-arch-linux-server-and-now-i-get-tmux-need-utf-8-locale-lc-ctype-bu
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Configuration

COPY login.defs /etc/login.defs
COPY login /etc/defaults/login
COPY personal/run.py /home/user/run.py
COPY personal/bashrc /home/user/.bashrc


RUN   \
     adduser --quiet --shell /bin/bash --gecos "User,101,," --disabled-password user \
  && chown -R user:user /home/user/ \
  && echo "user ALL=(ALL) NOPASSWD:ALL"  >> /etc/sudoers

USER user

# Commit to checkout and build.
ARG BRANCH=master
ARG commit=HEAD

RUN \
     cd /home/user \
  && git clone --depth=1 https://github.com/sagemathinc/cocalc.git \
  && cd cocalc \
  && git pull \
  && git fetch -u origin $BRANCH:$BRANCH \
  && git checkout ${commit:-HEAD}

USER root
RUN pip3 install /home/user/cocalc/src/smc_pyutil/

USER user

RUN cd /home/user/cocalc/src && npm run make

# And cleanup npm cache, which is several hundred megabytes after building cocalc above.
RUN rm -rf /home/user/.npm
COPY personal/run.py /home/user/run.py

CMD /home/user/run.py

ARG BUILD_DATE
LABEL org.label-schema.build-date=$BUILD_DATE

EXPOSE 5000
