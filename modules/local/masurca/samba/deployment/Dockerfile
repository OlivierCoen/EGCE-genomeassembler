FROM mambaorg/micromamba

USER $MAMBA_USER


RUN micromamba install --name base --yes --file /tmp/env.lock \
    && micromamba clean --all --yes

COPY --chown=$MAMBA_USER:$MAMBA_USER scripts /opt

ENV PATH="/opt:${PATH}"
WORKDIR /home

FROM mambaorg/micromamba:1.5.10-noble

COPY --chown=$MAMBA_USER:$MAMBA_USER conda-linux-64.lock /tmp/env.lock

RUN micromamba install --name base --yes --file /tmp/env.lock \
    && micromamba install -y -n base conda-forge::procps-ng \
    && micromamba env export --name base --explicit > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y

COPY --chown=$MAMBA_USER:$MAMBA_USER scripts /opt

USER root
ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"

# for samba scripts
ENV PATH="/opt:$PATH"
