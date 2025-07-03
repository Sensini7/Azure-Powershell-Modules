# FROM mcr.microsoft.com/azure-powershell:mariner-2

# # 1) Core tools via tdnf
# RUN tdnf install -y \
#       git \
#       openssh-clients \
#       file \
#       curl \
#       unzip \
#       jq \
#     && tdnf clean all

# # 2) Terraform – download & unzip
# ARG TERRAFORM_VERSION=1.4.6
# RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
#      -o /tmp/terraform.zip \
#  && unzip /tmp/terraform.zip -d /usr/local/bin \
#  && rm /tmp/terraform.zip

# # 3) (Optional) pre-install any PS modules you need
# # RUN pwsh -Command "Install-Module Microsoft.Graph.Identity.SignIns -Force"

# # 4) Install Python3 & pip (needed to get azure-cli via pip)
# RUN tdnf install -y python3 python3-pip \
#  && tdnf clean all

# # 5) Install Azure CLI via pip
# RUN pip3 install azure-cli

# # 6) (Optional) Install jwt-cli for easier JWT decoding
# RUN curl -Lo /usr/local/bin/jwt https://github.com/mike-engel/jwt-cli/releases/download/5.0.0/jwt-linux \
#  && chmod +x /usr/local/bin/jwt

# # 7) Install TFLint – download & unzip
# ARG TFLINT_VERSION=0.34.1
# RUN curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" \
#      -o /tmp/tflint.zip \
#  && unzip /tmp/tflint.zip -d /usr/local/bin \
#  && rm /tmp/tflint.zip

# # 8) Checkov – Terraform compliance scanner
# RUN pip3 install checkov

# # Entrypoint already set to pwsh



# ────────────────────────────────────────────────────────────────────────────────
# 0) Base: Azure PowerShell on Mariner 2
# ────────────────────────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/azure-powershell:mariner-2 AS base

# 1) Core OS tools
RUN tdnf install -y \
      git \
      openssh-clients \
      file \
      curl \
      unzip \
      jq \
    && tdnf clean all

# 2) Terraform
ARG TERRAFORM_VERSION=1.4.6
RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
     -o /tmp/terraform.zip \
 && unzip /tmp/terraform.zip -d /usr/local/bin \
 && rm /tmp/terraform.zip

# 3) Python & Azure CLI & Checkov
RUN tdnf install -y python3 python3-pip \
 && pip3 install azure-cli checkov \
 && tdnf clean all

# 4) jwt-cli
RUN curl -Lo /usr/local/bin/jwt \
     https://github.com/mike-engel/jwt-cli/releases/download/5.0.0/jwt-linux \
 && chmod +x /usr/local/bin/jwt

# 5) TFLint
ARG TFLINT_VERSION=0.34.1
RUN curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" \
     -o /tmp/tflint.zip \
 && unzip /tmp/tflint.zip -d /usr/local/bin \
 && rm /tmp/tflint.zip

# ────────────────────────────────────────────────────────────────────────────────
# 6) Install GitHub Actions Runner
# ────────────────────────────────────────────────────────────────────────────────
ARG RUNNER_VERSION=2.325.0
RUN mkdir -p /actions-runner \
 && cd /actions-runner \
 && curl -fsSL \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    -o /actions-runner/actions-runner.tar.gz \
 && tar -xzf /actions-runner/actions-runner.tar.gz -C /actions-runner \
 && rm /actions-runner/actions-runner.tar.gz

# 7) Entrypoint: run the runner
WORKDIR /home/runner
ENTRYPOINT ["./run.sh"]
