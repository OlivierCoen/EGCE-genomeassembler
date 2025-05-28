FROM mambaorg/micromamba:1.5.10-noble

ARG FOLDER
COPY --chown=$MAMBA_USER:$MAMBA_USER ${FOLDER}/spec-file.txt /tmp/spec-file.txt
RUN micromamba install -y -n base -f /tmp/spec-file.txt \
    && micromamba install -y -n base conda-forge::procps-ng \
    && micromamba env export --name base --explicit > environment.lock \
    && echo ">> CONDA_LOCK_START" \
    && cat environment.lock \
    && echo "<< CONDA_LOCK_END" \
    && micromamba clean -a -y

COPY --chown=$MAMBA_USER:$MAMBA_USER modified_pecat.pl /opt/conda/share/pecat-0.0.3-0/bin/modified_pecat.pl
COPY --chown=$MAMBA_USER:$MAMBA_USER launch_modified_pecat.sh /opt/conda/bin/launch_modified_pecat.sh
USER root
ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
