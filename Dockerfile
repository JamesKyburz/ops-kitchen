FROM amazonlinux:2 as base

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing base stuff" && \
  yum -y groupinstall "Development Tools" && \
  yum install -y pcre-devel xz-devel openssl wget jq python3

FROM base as shellcheck

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing shellcheck" && \
  scversion="stable" && \
  wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.linux.x86_64.tar.xz" | tar -xJv && \
  cp "shellcheck-${scversion}/shellcheck" /usr/bin/

FROM base as ag

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "install the silver searcher (ag)" && \
  git clone https://github.com/ggreer/the_silver_searcher.git && \
  (cd the_silver_searcher && ./build.sh && make install)

FROM base as awscli

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing aws-cli" && \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  ./aws/install

FROM base as bash-commons

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "bash commons" && \
  git clone --branch v0.1.3 https://github.com/gruntwork-io/bash-commons.git && \
  mkdir -p /opt/gruntwork && \
  cp -r bash-commons/modules/bash-commons/src /opt/gruntwork/bash-commons && \
  chown -R $USER:$(id -gn $USER) /opt/gruntwork/bash-commons

FROM base as go

ENV GOPATH /root/.go
ENV GOROOT /usr/local/go
ENV PATH "/usr/local/go/bin:${PATH}"
ENV PATH "/root/.go/bin:${PATH}"

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing go" && \
  curl https://storage.googleapis.com/golang/go1.15.1.linux-amd64.tar.gz -o go.tar.gz && \
  tar -xzf go.tar.gz && \
  mv go /usr/local && \
  rm -rf go.tar.gz && \
  log_info "installing shfmt" && \
  GO111MODULE=on go get mvdan.cc/sh/v3/cmd/shfmt

FROM base as docker

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing docker" && \
  amazon-linux-extras install docker && \
  log_info "installing docker-compose" && \
  curl -L https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing unzip" && \
  yum install -y unzip

FROM amazonlinux:2

LABEL maintainer="James Kyburz james.kyburz@gmail.com"

ENV GOPATH /root/.go
ENV GOROOT /usr/local/go
ENV PATH "/usr/local/go/bin:${PATH}"
ENV PATH "/root/.go/bin:${PATH}"
ENV DENO_INSTALL "/root/.deno"
ENV PATH "$DENO_INSTALL/bin:$PATH"

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "copying from multi-stage steps"

COPY --from=shellcheck /usr/bin/shellcheck /usr/bin/shellcheck
COPY --from=ag /usr/local/bin/ag /usr/local/bin/ag
COPY --from=awscli /usr/local/bin /usr/local/bin
COPY --from=awscli /usr/local/aws-cli /usr/local/aws-cli
COPY --from=docker /usr/bin/docker /usr/bin/docker
COPY --from=docker /usr/local/bin/docker-compose /usr/local/bin/docker-compose
COPY --from=go /root/.go/bin /root/.go/bin
COPY --from=bash-commons /opt/gruntwork/bash-commons /opt/gruntwork/bash-commons

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing base stuff" && \
  mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH" && \
  mkdir -p /root/.config && \
  chown -R $USER:$(id -gn $USER) /root/.config && \
  yum install -y python3 jq unzip openssl openssh-clients && \
  log_info "installing node" && \
  curl -sL https://rpm.nodesource.com/setup_12.x | bash - && \
  curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo && \
  yum install -y nodejs yarn && \
  log_info "installing latest npm" && \
  npm install npm@latest -g && \
  log_info "installing deno" && \
  curl -fsSL https://deno.land/x/install/install.sh | sh && \
  log_info "installing envsubst" && \
  curl -L https://github.com/a8m/envsubst/releases/download/v1.1.0/envsubst-"$(uname -s)"-"$(uname -m)" -o envsubst && \
  chmod +x envsubst && \
  mv envsubst /usr/local/bin && \
  log_info "installing aws-sam-cli" && \
  pip3 install --no-cache-dir aws-sam-cli && \
  log_info "installing awscurl" && \
  pip3 install --no-cache-dir awscurl && \
  log_info "installing yq" && \
  pip3 install --no-cache-dir yq && \
  log_info "installing 1password cli" && \
  curl https://cache.agilebits.com/dist/1P/op/pkg/v1.6.0/op_linux_amd64_v1.6.0.zip -o op.zip && \
  unzip op.zip && \
  chmod +x op && \
  mv op /usr/bin && \
  rm -rf op.zip op.sig && \
  terraform_latest=$(curl https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version') && \
  log_info "installing terraform ${terraform_latest:?}" && \
  curl https://releases.hashicorp.com/terraform/${terraform_latest:?}/terraform_${terraform_latest:?}_linux_amd64.zip -o terraform.zip && \
  unzip terraform.zip && \
  chmod +x terraform && \
  mv terraform /usr/bin && \
  rm -rf terraform.zip && \
  log_info "installing ecs cli" && \
  curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest && \
  chmod +x /usr/local/bin/ecs-cli && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  log_info "✨ ops-kitchen installation complete. ✨"

COPY .bashrc /root/.bashrc
