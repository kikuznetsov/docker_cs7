echo "Creating an SSH key for you..."
# ssh-keygen -t rsa

echo "Please add this public key to Github \n"
echo "https://github.com/account/ssh \n"
# read -p "Press [Enter] key after this..."

echo "Installing xcode-stuff"
xcode-select --install

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  export PATH="/opt/homebrew/bin:$PATH"
fi

# Update homebrew recipes
echo "Updating homebrew..."
brew update
brew upgrade

echo "Installing Git..."
brew install git

echo "Installing open-mpi..."
brew install open-mpi
brew install gcc
brew install g++
brew install autoconf
brew install automake
brew install libtool 

echo "Installing python3 and PyQT5..."
# brew install python3
# python3 -m pip install --upgrade pip
# python3 -m pip install PyQT5
# brew install pyqt5

echo "Installing othe dependences.."
brew install wget

softdir=${HOME}/Soft/CS_INSTALL
echo "code-saturne and its dependences will be installed into"
echo ${softdir}
mkdir ${softdir}

echo "Building hdf5 from source..."
hdfdir=${softdir}/hdf5
cd $softdir 
git clone -b 1.10/master https://github.com/HDFGroup/hdf5.git  hdf5.src
cd hdf5.src
./configure --prefix=${hdfdir}
make -j 2>&1 > /dev/null
make install 2>&1 > /dev/null

echo "Building med from source..."
meddir=${softdir}/med
mkdir ${meddir}
cd $softdir
wget https://files.salome-platform.org/Salome/other/med-4.1.0.tar.gz
tar xzf med-4.1.0.tar.gz 
cd med-4.1.0
echo "Applying patch on the configure file in order to define version of HDF5 properly.."
#make sed work as it is working under Linux
export LC_CTYPE=C
export LANG=C
#patch itself
sed -i'' -e "/H5\_VER\_MINOR=/ s_sed.*_awk \'{print \$3}\' \`_" configure
sed -i'' -e "/H5\_VER\_MAJOR=/ s_sed.*_awk \'{print \$3}\' \`_" configure
sed -i'' -e "/H5\_VER\_RELEASE=/ s_sed.*_awk \'{print \$3}\' \`_" configure
export LC_CTYPE=UTF-8
export LANG=""
echo "Configure MED and compile it"
./configure CC=mpicc CXX=mpic++ --prefix=${meddir} \
	 --with-med_int=long --disable-python --disable-fortran --with-hdf5=${hdfdir} 
make -j 2>&1 > /dev/null
make install 2>&1 > /dev/null


echo "Building code_saturne from sources..."
cd ${softdir}
cs_src_dir=${softdir}/code_saturne.src
cs_build_dir=${softdir}/code_saturne.build
mkdir ${cs_build_dir}
cs_install_dir=${softdir}/code_saturne.install
mkdir ${cs_install_dir}

git clone -b master https://github.com/code-saturne/code_saturne.git ${cs_src_dir}
cd ${cs_src_dir}
./sbin/bootstrap
cd ${cs_build_dir}
${cs_src_dir}/configure PYTHON=$(brew --prefix python3)/bin/python3 CC=mpicc FC=mpif90 CXX=mpic++ \
        --prefix=${cs_install_dir} --with-hdf5=${hdfdir} \
        --with-med=${meddir} \
	CFLAGS='-Wno-implicit-function-declaration -I/opt/homebrew/include/ -g' \
	FCFLAGS='-g' --enable-debug --enable-static
make -j 2>&1 > /dev/null
make install 2>&1 > /dev/null

echo "Fix dynamical libraries libple in code_saturne installation..."
otool -L ${cs_install_dir}/libexec/code_saturne/cs_solver

install_name_tool -change @rpath/libple.dylib.2 ${cs_install_dir}/lib/libple.dylib.2 ${cs_install_dir}/libexec/code_saturne/cs_solver

otool -L ${cs_install_dir}/libexec/code_saturne/cs_solver

