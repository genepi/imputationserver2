FROM continuumio/miniconda3
MAINTAINER Lukas Forer <lukas.forer@i-med.ac.at> / Sebastian Schönherr <sebastian.schoenherr@i-med.ac.at>
COPY environment.yml .
RUN \
   conda env update -n root -f environment.yml \
&& conda clean -a
RUN apt-get update && apt-get install -y build-essential unzip tabix  zlib1g-dev liblzma-dev libbz2-dev
RUN pip install cget

# Install jbang
ENV JBANG_VERSION=0.79.0
WORKDIR "/opt"
RUN wget https://github.com/jbangdev/jbang/releases/download/v${JBANG_VERSION}/jbang-${JBANG_VERSION}.zip && \
    unzip -q jbang-*.zip && \
    mv jbang-${JBANG_VERSION} jbang  && \
    rm jbang*.zip
ENV PATH="/opt/jbang/bin:${PATH}"

# Install eagle
ENV EAGLE_VERSION=2.4
WORKDIR "/opt"
RUN wget https://storage.googleapis.com/broad-alkesgroup-public/Eagle/downloads/old/Eagle_v${EAGLE_VERSION}.tar.gz && \
    tar xvfz Eagle_v${EAGLE_VERSION}.tar.gz && \
    rm Eagle_v${EAGLE_VERSION}.tar.gz && \
    mv Eagle_v${EAGLE_VERSION}/eagle /usr/bin/.

# Install eagle
ENV BEAGLE_VERSION=18May20.d20
WORKDIR "/opt"
RUN wget https://faculty.washington.edu/browning/beagle/beagle.${BEAGLE_VERSION}.jar && \
    mv beagle.${BEAGLE_VERSION}.jar /usr/bin/.


# Install bcftools
ENV BCFTOOLS_VERSION=1.13
WORKDIR "/opt"
RUN wget https://github.com/samtools/bcftools/releases/download/${BCFTOOLS_VERSION}/bcftools-${BCFTOOLS_VERSION}.tar.bz2  && \
    tar xvfj bcftools-${BCFTOOLS_VERSION}.tar.bz2 && \
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
ENV PGS_CALC_VERSION=v0.9.14
WORKDIR "/opt"
RUN wget https://github.com/lukfor/pgs-calc/releases/download/${PGS_CALC_VERSION}/installer.sh  && \
    bash installer.sh && \
    mv pgs-calc.jar /usr/bin/.

# Install imputationserver-utils
ENV IMPUTATIONSERVER_UTILS_VERSION=v1.7.0
RUN mkdir /opt/imputationserver-utils
WORKDIR "/opt/imputationserver-utils"
RUN wget https://github.com/genepi/imputationserver-utils/releases/download/${IMPUTATIONSERVER_UTILS_VERSION}/imputationserver-utils.tar.gz
RUN tar xvfz imputationserver-utils.tar.gz
RUN chmod +x /opt/imputationserver-utils/bin/tabix