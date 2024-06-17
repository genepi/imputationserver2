FROM ubuntu:22.04
LABEL Lukas Forer <lukas.forer@i-med.ac.at> / Sebastian Schönherr <sebastian.schoenherr@i-med.ac.at>

# Install compilers
RUN apt-get update && \
    apt-get install -y wget build-essential zlib1g-dev liblzma-dev libbz2-dev libxau-dev && \
    apt-get -y clean

#  Install miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py39_23.9.0-0-Linux-x86_64.sh -O ~/miniconda.sh && \
  /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=/opt/conda/bin:${PATH}

COPY environment.yml .
RUN conda update -y conda && \
    conda env update -n root -f environment.yml && \
    conda clean --all

# Install eagle
ENV EAGLE_VERSION=2.4.1
WORKDIR "/opt"
# RUN wget https://storage.googleapis.com/broad-alkesgroup-public/Eagle/downloads/old/Eagle_v${EAGLE_VERSION}.tar.gz && \
RUN wget https://storage.googleapis.com/broad-alkesgroup-public/Eagle/downloads/Eagle_v2.4.1.tar.gz && \
    tar xvfz Eagle_v${EAGLE_VERSION}.tar.gz && \
    rm Eagle_v${EAGLE_VERSION}.tar.gz && \
    mv Eagle_v${EAGLE_VERSION}/eagle /usr/bin/.

# Install beagle
ENV BEAGLE_VERSION=18May20.d20
WORKDIR "/opt"
RUN wget https://faculty.washington.edu/browning/beagle/beagle.${BEAGLE_VERSION}.jar && \
    mv beagle.${BEAGLE_VERSION}.jar /usr/bin/.

# Install bcftools
ENV BCFTOOLS_VERSION=1.13
WORKDIR "/opt"
RUN wget https://github.com/samtools/bcftools/releases/download/${BCFTOOLS_VERSION}/bcftools-${BCFTOOLS_VERSION}.tar.bz2  && \
    tar xvfj bcftools-${BCFTOOLS_VERSION}.tar.bz2 && \
    rm bcftools-${BCFTOOLS_VERSION}.tar.bz2 && \
    cd  bcftools-${BCFTOOLS_VERSION}  && \
    ./configure  && \
    make && \
    make install

# Install minimac4
WORKDIR "/opt"
RUN mkdir minimac4
COPY files/bin/minimac4 minimac4/.
ENV PATH="/opt/minimac4:${PATH}"
RUN chmod +x /opt/minimac4/minimac4

# Install PGS-CALC
ENV PGS_CALC_VERSION="1.6.1"
RUN mkdir /opt/pgs-calc
WORKDIR "/opt/pgs-calc"
RUN wget https://github.com/lukfor/pgs-calc/releases/download/v${PGS_CALC_VERSION}/pgs-calc-${PGS_CALC_VERSION}.tar.gz && \
    tar -xf pgs-calc-*.tar.gz && \
    rm pgs-calc-*.tar.gz
ENV PATH="/opt/pgs-calc:${PATH}"

# Install imputationserver-utils
ENV IMPUTATIONSERVER_UTILS_VERSION=v1.2.1
RUN mkdir /opt/imputationserver-utils
WORKDIR "/opt/imputationserver-utils"
RUN wget https://github.com/genepi/imputationserver-utils/releases/download/${IMPUTATIONSERVER_UTILS_VERSION}/imputationserver-utils.tar.gz && \
    tar xvfz imputationserver-utils.tar.gz && \
    rm imputationserver-utils.tar.gz && \
    chmod +x /opt/imputationserver-utils/bin/tabix

# Install ccat
ENV CCAT_VERSION=1.1.0
RUN wget https://github.com/jingweno/ccat/releases/download/v${CCAT_VERSION}/linux-amd64-${CCAT_VERSION}.tar.gz && \
    tar xfz linux-amd64-${CCAT_VERSION}.tar.gz && \
    rm linux-amd64-${CCAT_VERSION}.tar.gz && \
    cp linux-amd64-${CCAT_VERSION}/ccat /usr/local/bin/ && \
    chmod +x /usr/local/bin/ccat

# Install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

# Needed, because imputationserver-utils starts process (e.g. tabix)
ENV JAVA_TOOL_OPTIONS="-Djdk.lang.Process.launchMechanism=vfork"

COPY files/bin/trace /usr/bin/.
COPY files/bin/vcf2geno /usr/bin/.
