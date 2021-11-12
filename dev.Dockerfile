FROM ubuntu:20.04 as main
SHELL ["/bin/bash", "-c"]
ENV TZ="UTC"
ENV LANG="en_US.UTF-8"
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt update && \
    apt dist-upgrade -y && \
    apt install -y --no-install-recommends \
        awscli \
        bash-completion \
        bind9-dnsutils \
        curl \
        docker.io \
        file \
        g++ \
        gcc \
        git \
        gnupg \
        jq \
        libc6-dev \
        make \
        moreutils \
        openssh-server \
        pkg-config \
        python3-minimal \
        python3-pip \
        shellcheck \
        sudo \
        tree \
        unzip \
        wget \
        && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd

COPY --from=golang:1.17 /usr/local/go /usr/local/

# kubectl
FROM curlimages/curl:latest as kubectl
RUN curl \
        -o /tmp/kubectl \
        -sL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod a+rx /tmp/kubectl

#########
FROM main
COPY --from=kubectl /tmp/kubectl /usr/local/bin/
ARG CUSER="dev"
RUN adduser \
        --disabled-password \
        --gecos '' \
        ${CUSER} && \
    echo "${CUSER}:${CUSER}" \
        | chpasswd && \
    usermod -aG root ${CUSER} && \
    echo "${CUSER} ALL=(ALL:ALL) NOPASSWD: ALL" \
        >> /etc/sudoers && \
    kubectl completion bash \
        > /etc/bash_completion.d/kubectl

USER ${CUSER}
ENV PATH="/usr/local/go/bin:/home/${CUSER}/go/bin:${PATH}"
RUN go get -v \
        golang.org/x/tools/gopls \
        github.com/uudashr/gopkgs/v2/cmd/gopkgs@latest \
        github.com/ramya-rao-a/go-outline@latest \
        github.com/cweill/gotests/gotests@latest \
        github.com/fatih/gomodifytags@latest \
        github.com/josharian/impl@latest \
        github.com/haya14busa/goplay/cmd/goplay@latest \
        github.com/go-delve/delve/cmd/dlv@latest \
        honnef.co/go/tools/cmd/staticcheck@latest \
        golang.org/x/tools/gopls@latest

