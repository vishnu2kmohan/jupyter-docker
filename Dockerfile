FROM debian:jessie

MAINTAINER Vishnu Mohan <vishnu@mesosphere.com>

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    SHELL=/bin/bash \
    TINI_URL=https://github.com/krallin/tini/releases \
    CONDA_URL=https://repo.continuum.io/archive \
    CONDA_INSTALLER=Anaconda3-2.4.0-Linux-x86_64.sh \
    CONDA_DIR=/opt/conda \
    CONDA_USER=conda \
    CONDA_UID=1000 \
    CONDA_USER_HOME=/home/conda \
    PATH=/opt/conda/bin:$PATH

RUN apt-get update -yq --fix-missing \
    && apt-get install -yq locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && apt-get install -yq \
       bzip2 \
       ca-certificates \
       curl \
       git \
       jq \
       libglib2.0-0 \
       libsm6 \
       libxext6 \
       libxrender1 \
       openssh-client \
       sudo \
       unzip \
       vim \
       wget \
    && apt-get clean

RUN cd /tmp \
    && TINI_VERSION=`curl -sS "${TINI_URL}"/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` \
    && wget --quiet "${TINI_URL}/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" \
    && dpkg -i "tini_${TINI_VERSION}.deb" \
    && apt-get clean \
    && wget --quiet "${CONDA_URL}/${CONDA_INSTALLER}" \
    && bash ./"${CONDA_INSTALLER}" -b -p /opt/conda \
    && echo 'export PATH=$CONDA_DIR/bin:$PATH' > /etc/profile.d/conda.sh \
    && conda update --quiet --yes --all \
    && conda clean --yes --tarballs \
    && conda clean --yes --packages \
    && rm /tmp/* \
    && useradd -m -s /bin/bash -g users -N -u $CONDA_UID $CONDA_USER

USER conda                                                                      
RUN conda create --quiet -n conda3 --clone=${CONDA_DIR} \
    && mkdir -p ${CONDA_USER_HOME}/work \
    && mkdir -p ${CONDA_USER_HOME}/.jupyter

EXPOSE 8888
WORKDIR ${CONDA_USER_HOME}/work
ENTRYPOINT ["tini", "--"]
CMD ["notebook.sh"]

# Add local files as late as possible to stay cache friendly
COPY notebook.sh /usr/local/bin/
COPY jupyter_notebook_config.py ${CONDA_USER_HOME}/.jupyter/
