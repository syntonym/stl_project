#!/bin/bash

mkdir plasma_install 
mkdir $HOME/lib 
mkdir $HOME/lib/libs 
mkdir $HOME/lib/include
cd plasma_install

#OPENBLAS
wget http://github.com/xianyi/OpenBLAS/archive/v0.2.19.zip
unzip v0.2.19.zip
cd OpenBLAS-0.2.19
make USE_THREAD=0
make install PREFIX=$HOME/lib/openblas
cp $HOME/lib/openblas/lib/*.a $HOME/lib/libs 
cp $HOME/lib/openblas/lib/*.so $HOME/lib/libs
cp $HOME/lib/openblas/lib/*.0 $HOME/lib/libs
cp $HOME/lib/openblas/include/*.h $HOME/lib/include
cd ..

#LAPACK
wget http://www.netlib.org/lapack/lapack-3.6.1.tgz
tar -xzvf lapack-3.6.1.tgz
cd lapack-3.6.1
cp make.inc.example make.inc
sed -i 's!../../librefblas.a!'"$HOME"'/lib/libs/libopenblas.a!g' make.inc
sed -i 's!../../libcblas.a!'"$HOME"'/lib/libs/libopenblas.a!g' make.inc
ulimit -s 65000
make
mkdir $HOME/lib/lapack
mkdir $HOME/lib/lapack/include 
mkdir $HOME/lib/lapack/lib
cp */include/*.h $HOME/lib/lapack/include
cp *.a $HOME/lib/lapack/lib
cd ..

#PLASMA
wget http://icl.cs.utk.edu/projectsfiles/plasma/pubs/plasma-installer_2.8.0.tar.gz
tar -xzvf plasma-installer_2.8.0.tar.gz
cd plasma-installer_2.8.0
export PKG_CONFIG_PATH=/usr/lib/pkgconfig
./setup.py --prefix=$HOME/lib/plasma --blaslib=$HOME/lib/openblas/lib/libopenblas.a --cblaslib=$HOME/lib/openblas/lib/libopenblas.a --lapacklib=$HOME/lib/lapack/lib/liblapack.a --notesting --downlapc
cp $HOME/lib/plasma/include/*.h $HOME/lib/include
cp $HOME/lib/plasma/lib/*.a $HOME/lib/libs
cd ..
