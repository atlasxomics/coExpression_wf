FROM 812206152185.dkr.ecr.us-west-2.amazonaws.com/latch-base:dd8f-main
RUN apt-get update -y
RUN apt-get install -y gdebi-core 
RUN apt install -y aptitude
RUN aptitude install -y libjpeg-dev
RUN apt-get update -y

# Install R
RUN apt-get update -y && \
    apt-get install -y \
        r-base \
        r-base-dev \
        apt-transport-https \
        build-essential \
        gfortran \
        libhdf5-dev \
        libatlas-base-dev \
        libbz2-dev \        
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libgit2-dev \
        libgsl-dev \
        libicu-dev \
        liblzma-dev \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libpcre3-dev \
        libssl-dev \
        libtcl8.6 \
        libtiff5 \
        libtk8.6 \
        libxml2-dev \
        libxt-dev \
        libx11-dev \
        libtiff-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        locales \
        make \
        pandoc \
        tzdata \
        vim \
        wget \
        zlib1g-dev \
        r-cran-rjava        

RUN echo "alias ll='ls -l --color=auto'" >> .bashrc
RUN echo "TZ=$( cat /etc/timezone )" >> /etc/R/Renviron.site

# Install devtools, cairo (https://stackoverflow.com/questions/20923209)
RUN apt-get install -y r-cran-devtools libcairo2-dev
# libglpk-dev

# Install packages
RUN R -e "install.packages(c('BiocManager', \
    'Cairo', \
    'Matrix', \
    'shiny', \
    'shinyhelper', \
    'data.table', \
    'Matrix', \
    'DT', \
    'magrittr', \
    'ggplot2', \
    'ggrepel', \
    'hdf5r', \
    'ggdendro', \
    'gridExtra', \
    'ggseqlogo', \
    'circlize', \
    'tidyverse', \
    'qdap'))"

RUN R -e "devtools::install_github('SGDDNB/ShinyCell')"
RUN R -e "BiocManager::install('ComplexHeatmap')"

# Upgrade R to version 4.3.0
RUN wget https://cran.r-project.org/src/base/R-4/R-4.3.0.tar.gz
RUN tar zxvf R-4.3.0.tar.gz
RUN cd R-4.3.0 && ./configure --enable-R-shlib
RUN cd R-4.3.0 && make && make install
RUN apt-get update -y && apt-get install -y default-jdk
RUN R CMD javareconf

RUN R -e "install.packages(c('pkgconfig', \
    'munsell', \
    'zip', \
    'zoo', \
    'xtable', \
    'listenv', \
    'lazyeval', \
    'bit64', \
    'rJava', \
    'labeling'), \
    repos = 'http://cran.us.r-project.org')"

RUN apt-get update -y && apt-get install -y libpoppler-cpp-dev 
RUN R -e "install.packages(c('pdftools') ,repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages(c('patchwork') ,repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages(c('bitops') ,repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages(c('XML') ,repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages(c('generics') ,repos = 'http://cran.us.r-project.org')"

RUN R -e 'install.packages("miniUI", dependencies = TRUE, repos = "http://cran.us.r-project.org")'
RUN R -e 'install.packages("mime", dependencies = TRUE, repos = "http://cran.us.r-project.org")'
RUN R -e 'install.packages("httpuv", dependencies = TRUE, repos = "http://cran.us.r-project.org")'
RUN R -e 'BiocManager::install(version = "3.18", ask = FALSE)'
RUN R -e 'BiocManager::install("multtest", update = TRUE)'
RUN R -e 'install.packages("mutoss", dependencies = TRUE, repos = "http://cran.us.r-project.org")'
RUN R -e 'install.packages("distrEx", dependencies = TRUE, repos = "http://cran.us.r-project.org")'
RUN apt-get install libfftw3-dev -y
RUN R -e 'install.packages("qqconf", dependencies = TRUE, repos = "http://cran.us.r-project.org")'
RUN R -e 'install.packages("metap", dependencies = TRUE, repos = "http://cran.us.r-project.org")'

RUN R -e 'install.packages("qdap", dependencies = TRUE, repos = "http://cran.us.r-project.org")'
RUN R -e 'install.packages("Seurat", dependencies = TRUE, repos = "http://cran.us.r-project.org")'
RUN python3 -m pip install numpy==1.26.2
RUN python3 -m pip install macs2==2.2.6

# STOP HERE:
# The following lines are needed to ensure your build environement works
# correctly with latch.
RUN python3 -m pip install --upgrade latch
COPY wf /root/wf
RUN mkdir /opt/latch
# Latch workflow registration metadata
# DO NOT CHANGE
ARG tag
ENV FLYTE_INTERNAL_IMAGE $tag
WORKDIR /root
