FROM amazon/aws-cli as aws-cli
FROM koalaman/shellcheck:stable as shellcheck

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
  log_info "installing shellcheck"
COPY --from=shellcheck /bin/shellcheck /bin/shellcheck

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing aws-cli"
COPY --from=aws-cli /usr/local/bin/aws /usr/local/bin/aws

RUN \
  log_info() { echo -e "\033[0m\033[1;94m${*}\033[0m"; } && \
  log_info "installing base stuff" && \
  mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH" && \
  mkdir -p /root/.config && \
  chown -R $USER:$(id -gn $USER) /root/.config && \
  yum -y groupinstall "Development Tools" && \
  yum install -y pcre-devel xz-devel openssl wget jq procps which python3 && \
  log_info "installing node" && \
  curl -sL https://rpm.nodesource.com/setup_12.x | bash - && \
  curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo && \
  yum install -y nodejs yarn && \
  log_info "installing deno" && \
  curl -fsSL https://deno.land/x/install/install.sh | sh && \
  log_info "installing go" && \
  curl https://storage.googleapis.com/golang/go1.15.1.linux-amd64.tar.gz -o go.tar.gz && \
  tar -xzf go.tar.gz && \
  mv go /usr/local && \
  rm -rf go.tar.gz && \
  log_info "installing docker" && \
  amazon-linux-extras install docker && \
  log_info "installing docker-compose" && \
  curl -L https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose && \
  log_info "installing envsubst" && \
  curl -L https://github.com/a8m/envsubst/releases/download/v1.1.0/envsubst-"$(uname -s)"-"$(uname -m)" -o envsubst && \
  chmod +x envsubst && \
  mv envsubst /usr/local/bin && \
  log_info "installing node-prune" && \
  go get github.com/tj/node-prune && \
  log_info "install the silver searcher (ag)" && \
  git clone https://github.com/ggreer/the_silver_searcher.git && \
  (cd the_silver_searcher && ./build.sh && make install) && \
  rm -rf the_silver_searcher && \
  log_info "installing shfmt" && \
  go get github.com/mvdan/sh/cmd/shfmt && \
  log_info "installing node-prune" && \
  go get github.com/tj/node-prune && \
  pip3 install wheel && \
  log_info "installing aws-sam-cli" && \
  pip3 install aws-sam-cli && \
  log_info "installing awscurl" && \
  pip3 install awscurl && \
  log_info "installing yq" && \
  pip3 install yq && \
  log_info "installing latest npm" && \
  npm install npm@latest -g && \
  log_info "installing global npm modules" && \
  npm install dynamodb-query-cli node-gyp yamljs babel-cli picture-tube modclean serverless -g && \
  log_info "installing 1password cli" && \
  curl https://cache.agilebits.com/dist/1P/op/pkg/v1.6.0/op_linux_amd64_v1.6.0.zip -o op.zip && \
  unzip op.zip && \
  chmod +x op && \
  mv op /usr/bin && \
  rm -rf op.zip op.sig && \
  log_info "installing ecs cli" && \
  curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest && \
  chmod +x /usr/local/bin/ecs-cli && \
  log_info "checking latest terraform version" && \
  terraform_latest=$(curl https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version') && \
  log_info "installing terraform ${terraform_latest:?}" && \
  curl https://releases.hashicorp.com/terraform/${terraform_latest:?}/terraform_${terraform_latest:?}_linux_amd64.zip -o terraform.zip && \
  unzip terraform.zip && \
  chmod +x terraform && \
  mv terraform /usr/bin && \
  rm -rf terraform.zip && \
  log_info "yum update & clean" && \
  yum update -y && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  log_info "✨ ops-kitchen installation complete. ✨"

COPY .bashrc /root/.bashrc
