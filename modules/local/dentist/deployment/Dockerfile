FROM mambaorg/micromamba:1.5.10-noble

ARG VERSION=v4.0.0.x86_64

USER root
RUN apt-get update \
    && apt-get install -y wget

RUN chown -R $MAMBA_USER:$MAMBA_USER /opt
WORKDIR /opt

USER $MAMBA_USER

RUN wget https://github.com/a-ludi/dentist/releases/download/v4.0.0/dentist.${VERSION}.tar.gz \
    && tar -xzf dentist.${VERSION}.tar.gz

ENV PATH="/opt/dentist.${VERSION}/bin:${PATH}"

COPY --chown=$MAMBA_USER:$MAMBA_USER conda-linux-64.lock /tmp/env.lock

# installing dependencies (in particular snakemake)
RUN micromamba install --name base --yes --file /tmp/env.lock \
    && micromamba install -y -n base conda-forge::procps-ng \
    && micromamba env export --name base --explicit > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y

WORKDIR /tmp


