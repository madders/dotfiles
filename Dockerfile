FROM ubuntu:groovy

ARG USER_ID=501
ARG GROUP_ID=20
ARG USER_NAME=mmaddern
ARG PASSWORD=docker

ENV DEBIAN_FRONTEND noninteractive
ENV TERM alacritty

RUN apt-get update && \
    apt-get install --no-install-recommends --quiet --yes \
      apt-utils \
      locales && \
    rm -rf /var/lib/apt/lists/* /root/.cache && \
    locale-gen en_GB.UTF-8

ENV LC_ALL en_GB.UTF-8
ENV LANG en_GB.UTF-8

RUN yes | unminimize

RUN apt-get update && \
    apt-get install --no-install-recommends --quiet --yes \
      ant \
      autoconf \
      build-essential \
      curl \
      default-jdk-headless \
      erlang-dev \
      erlang-nox \
      fish \
      git \
      less \
      libxml2-utils \
      markdown \
      neovim \
      npm \
      python3-neovim \
      python-is-python3 \
      python3-pip \
      ssh-client \
      sudo \
      tmux \
      vifm \
      xsltproc && \
    rm -rf /var/lib/apt/lists/* /root/.cache

RUN git -C /tmp clone https://github.com/alacritty/alacritty.git && \
    tic -xe alacritty,alacritty-direct /tmp/alacritty/extra/alacritty.info && \
    rm -rf /tmp/alacritty

RUN git -C /tmp clone https://github.com/hawk/lux.git && cd /tmp/lux && \
    autoconf && ./configure && make && make install && \
    rm -rf /tmp/lux

RUN useradd --no-log-init \
            --create-home \
            --shell /usr/bin/fish \
            --uid ${USER_ID} \
            --gid ${GROUP_ID} \
            --groups sudo \
            ${USER_NAME} && \
    echo "${USER_NAME}:${PASSWORD}" | chpasswd

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

RUN mkdir git
COPY --chown=${USER_ID}:${GROUP_ID} dotfiles git/dotfiles
RUN make -C git/dotfiles

RUN PATH=~/.local/bin:$PATH pip3 install \
      requests \
      pyang \
      pylint \
      pygments

COPY --chown=${USER_ID}:${GROUP_ID} nso-installer nso-installer
RUN if [ -n "$(ls -A nso-installer)" ]; then \
      for NSO_INSTALLER in nso-installer/*; do \
        NSO_VERSION=$(echo ${NSO_INSTALLER} | sed \
          's/^nso-installer\/nso-\(.*\)\.linux\.x86_64\.installer\.bin$/\1/'); \
        sh ${NSO_INSTALLER} nso-${NSO_VERSION}; \
      done; \
      ln -s nso-${NSO_VERSION} nso-current; \
    fi && \
    rm -rf nso-installer

RUN rm -rf git

CMD ["/usr/bin/tmux", "new-session", "-s", "dev-docker"]