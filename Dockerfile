FROM ubuntu:24.04
LABEL creator="TOPMed Imputation Server Team <imputationserver@umich.edu>"

# Install compilers
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget build-essential zlib1g-dev liblzma-dev libbz2-dev libxau-dev libgsl-dev && \
    apt-get -y clean

#  Install miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py312_25.7.0-2-Linux-x86_64.sh -O ~/miniconda.sh && \
  /bin/bash ~/miniconda.sh -b -p /opt/conda
ENV PATH=/opt/conda/bin:${PATH}

COPY environment.yml .
RUN conda tos accept && \
    conda update -y conda && \
    conda env update -n root -f environment.yml && \
    conda update --all && \
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
# ENV BEAGLE_VERSION=27Feb25.75f
# WORKDIR "/opt"
# RUN wget https://faculty.washington.edu/browning/beagle/beagle.${BEAGLE_VERSION}.jar && \
#     mv beagle.${BEAGLE_VERSION}.jar /usr/bin/beagle.jar

# Install minimac4
ENV MINIMAC_VERSION=4.1.6
WORKDIR "/opt"
RUN wget https://github.com/statgen/Minimac4/releases/download/v${MINIMAC_VERSION}/minimac4-${MINIMAC_VERSION}-Linux-x86_64.sh && \
    chmod u+x /opt/minimac4-${MINIMAC_VERSION}-Linux-x86_64.sh && \
    /opt/minimac4-${MINIMAC_VERSION}-Linux-x86_64.sh --skip-license --prefix=/opt && \
    mv /opt/bin/minimac4 /usr/bin/ && \
    rm -r /opt/bin && \
    rm /opt/minimac4-${MINIMAC_VERSION}-Linux-x86_64.sh

# Install PGS-CALC
ENV PGS_CALC_VERSION=1.6.1
RUN mkdir /opt/pgs-calc
WORKDIR "/opt/pgs-calc"
RUN wget https://github.com/lukfor/pgs-calc/releases/download/v${PGS_CALC_VERSION}/pgs-calc-${PGS_CALC_VERSION}.tar.gz && \
    tar -xf pgs-calc-*.tar.gz && \
    rm pgs-calc-*.tar.gz
ENV PATH="/opt/pgs-calc:${PATH}"

# Install imputationserver-utils
ENV IMPUTATIONSERVER_UTILS_VERSION=1.5.4-statgen.1
RUN mkdir /opt/imputationserver-utils
WORKDIR "/opt/imputationserver-utils"
RUN wget https://github.com/statgen/imputationserver-utils/releases/download/v${IMPUTATIONSERVER_UTILS_VERSION}/imputationserver-utils.tar.gz && \
    tar xvfz imputationserver-utils.tar.gz && \
    rm imputationserver-utils.tar.gz

# Install vcf2geno and trace
ENV LASER_VERSION=2.04
WORKDIR "/opt"
RUN wget http://csg.sph.umich.edu/chaolong/LASER/LASER-2.04.tar.gz && \
    tar xfz LASER-2.04.tar.gz && \
    mv LASER-2.04/trace /usr/bin/ && \
    mv LASER-2.04/vcf2geno/vcf2geno /usr/bin/ && \
    rm LASER-2.04.tar.gz

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

# Needed, because bioconda does not correctly installs dependencies for bcftools
RUN ln -s /lib/x86_64-linux-gnu/libgsl.so.27 /opt/conda/lib/libgsl.so.25
