#!/bin/bash

if [ -z ${INSTALL_PREFIX+x} ]; 
	then 
		echo "Please provide and install prefix in the env INSTALL_PREFIX"
		echo "INSTALL_PREFIX is unset, aborting installation..."
		exit 1
fi

mkdir plasma_install
mkdir $INSTALL_PREFIX
mkdir $INSTALL_PREFIX/lib
mkdir $INSTALL_PREFIX/include
cd plasma_install

#OPENBLAS
wget http://github.com/xianyi/OpenBLAS/archive/v0.2.19.zip
unzip v0.2.19.zip
cd OpenBLAS-0.2.19
make USE_THREAD=0
make install PREFIX=$INSTALL_PREFIX
cd ..

#LAPACK
wget http://www.netlib.org/lapack/lapack-3.6.1.tgz
tar -xzvf lapack-3.6.1.tgz
cd lapack-3.6.1
cp make.inc.example make.inc
sed -i 's!../../librefblas.a!'"$INSTALL_PREFIX"'/lib/libopenblas.a!g' make.inc
sed -i 's!../../libcblas.a!'"$INSTALL_PREFIX"'/lib/libopenblas.a!g' make.inc
ulimit -s 65000
make
mkdir $HOME/lib/lapack
mkdir $HOME/lib/lapack/include 
mkdir $HOME/lib/lapack/lib
cp */include/*.h $INSTALL_PREFIX/include/
cp *.a $INSTALL_PREFIX/lib
cd ..

#PLASMA
wget http://icl.cs.utk.edu/projectsfiles/plasma/pubs/plasma-installer_2.8.0.tar.gz
tar -xzvf plasma-installer_2.8.0.tar.gz
cd plasma-installer_2.8.0
export PKG_CONFIG_PATH=/usr/lib/pkgconfig
./setup.py --prefix=$INSTALL_PREFIX --blaslib=$INSTALL_PREFIX/lib/libopenblas.a --cblaslib=$INSTALL_PREFIX/lib/libopenblas.a --lapacklib=$INSTALL_PREFIX/lib/liblapack.a --notesting --downlapc
cp $INSTALL_PREFIX/plasma/include/*.h $INSTALL_PREFIX/include
cp $INSTALL_PREFIX/plasma/lib/*.a $INSTALL_PREFIX/lib/
rm -r $INSTALL_PREFIX/plasma/
cd ..

#Create Makefile
cp template_Makefile Makefile
sed -i 's!{$INSTALL_PREFIX}!'"$INSTALL_PREFIX"'!g' Makefile
