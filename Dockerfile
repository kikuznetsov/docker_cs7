# syntax=docker/dockerfile:1
FROM ubuntu:20.04
RUN mkdir /home/app
RUN mkdir /home/app/soft
RUN mkdir /home/app/soft/code_saturne.build
# change from the default /bin/sh to /bin/bash
SHELL ["/bin/bash", "-c"]
# install the packages
RUN apt-get -y update && apt upgrade -y
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
RUN apt-get install -y tzdata
RUN apt-get install -y gcc g++ mpi mpich  git automake libtool gfortran make cmake vim python3 python3-dev ssh python3-pyqt5 pyqt5-dev-tools qttools5-dev-tools
# make a symbolic link for the mpi libs
RUN cd /usr/include && ln -s /usr/include/x86_64-linux-gnu/mpich/* .
RUN cd /usr/bin && ln -s /usr/bin/python3 python

# install hdf5 and med
RUN cd /home/app/soft && git clone -b 1.10/master https://github.com/HDFGroup/hdf5.git hdf5-src
RUN cd /home/app/soft/hdf5-src && ./configure --prefix=/home/app/soft/hdf5
RUN  cd /home/app/soft/hdf5-src && make -j8 && make install

RUN cd /home/app/soft && wget https://files.salome-platform.org/Salome/other/med-4.1.0.tar.gz
RUN cd /home/app/soft && tar xzvf med-4.1.0.tar.gz
## applying the patch to successefully compile the code
## there is a bug in med-4.1.0/configure. We need to replace the following line by awk '{print $3}':
## sed  's/^.*H5_VERS_MAJOR[[ \t]]*\([0-9]*\)[[ \t]]*.*$/\1/g'

############################### Patch:
RUN cd /home/app/soft/med-4.1.0 && sed -i "/H5\_VER\_MINOR=/ s_sed.*_awk \'{print \$3}\' \`_" configure
RUN cd /home/app/soft/med-4.1.0 && sed -i "/H5\_VER\_MAJOR=/ s_sed.*_awk \'{print \$3}\' \`_" configure
RUN cd /home/app/soft/med-4.1.0 && sed -i "/H5\_VER\_RELEASE=/ s_sed.*_awk \'{print \$3}\' \`_" configure
################################End of Path ##########################################

# configure and compile
RUN cd /home/app/soft/med-4.1.0 && ./configure --prefix=/home/app/soft/med --with-hdf5=/home/app/soft/hdf5 --disable-dependency-tracking
RUN cd /home/app/soft/med-4.1.0 && make -j8 && make install

# configure and install code_saturne
# RUN git clone -b v7.1 https://github.com/code-saturne/code_saturne.git
RUN cd /home/app/soft && git clone -b master https://github.com/code-saturne/code_saturne.git
RUN cd /home/app/soft/code_saturne && ./sbin/bootstrap #run the automake tools
# sometimes a problem with build-aux could appear in this case need to run
RUN cd /home/app/soft/code_saturne && autoreconf -vif
RUN cd /home/app/soft/code_saturne.build && ../code_saturne/configure --prefix=/home/app/soft/code_saturne.install --with-hdf5=/home/app/soft/hdf5 --with-med=/home/app/soft/med --enable-debug CC=mpicc PYTHON=/usr/bin/python3 --disable-static
# in case of problem with PLE during configure or compilation check MPI installation
RUN cd /home/app/soft/code_saturne.build && make -j8 && make install
# CS will be installed into
# /home/app/soft/code_saturne.install/bin/code_saturne
WORKDIR /home/app/
CMD /home/app/soft/code_saturne.install/bin/code_saturne info --version
# As the next steps we should copy working folder from gitlab and run
