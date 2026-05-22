FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

ENV MAMBA_ROOT_PREFIX=/opt/conda \
    MAMBA_EXE=/usr/local/bin/micromamba \
    PATH=/opt/conda/bin:$PATH \
    NXF_EDGE=0 \
    NXF_VER=26.04.1 \
    NXF_HOME=/workspaces/.nextflow \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1

COPY conda.yml /tmp/conda.yml

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl bzip2 \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://micro.mamba.pm/api/micromamba/linux-64/1.5.10 \
        | tar -xvj -C /usr/local/bin --strip-components=1 bin/micromamba \
    && mkdir -p "${MAMBA_ROOT_PREFIX}" \
    && micromamba install -y -n base -f /tmp/conda.yml \
    && micromamba env export --name base --explicit > /opt/conda/environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat /opt/conda/environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y \
    && rm -f /tmp/conda.yml

RUN chmod -R a+rX "${MAMBA_ROOT_PREFIX}" \
    && nextflow -version \
    && nf-core --version \
    && nf-test version \
    && mkdocs --version

USER vscode
WORKDIR /workspaces
