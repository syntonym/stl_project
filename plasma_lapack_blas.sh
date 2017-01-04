#!/bin/bash

WORKING_DIR=$(pwd)

if [ -z ${BUILD_DIR+x} ];
then
	BUILD_DIR=_build
fi

if [ -z ${INSTALL_PREFIX+x} ]; 
then 
	echo "Please provide and install prefix in the env INSTALL_PREFIX"
	echo "INSTALL_PREFIX is unset, aborting installation..."
	exit 1
fi

if [ ! -d $BUILD_DIR ]
then
	mkdir $BUILD_DIR
	__build_dir_created=yes
fi

cd $BUILD_DIR
mkdir $INSTALL_PREFIX
mkdir $INSTALL_PREFIX/lib
mkdir $INSTALL_PREFIX/include

# OPENBLAS
#
# Usage: install_openblas BUILD_DIR INSTALL_PREFIX USE_THREAD
#
# Installs Openblas
#
# Args:
# 	BUILD_DIR      (path) - path to build dir which we can use
# 	INSTALL_PREFIX (path) - path where to install to
# 	USE_THREAD     (int)  - passed to openblas installer

install_openblas() {

	BUILD_DIR=$1
	INSTALL_PREFIX=$2
	USE_THREAD=$3
	OLD_DIR=$(pwd)

	if [ -z ${BUILD_DIR+x} ];
	then
		echo "Error in install_openblas: BUILD_DIR is empty"
		exit 1
	fi

	if [ ! -d $BUILD_DIR/open_blas]
	then
		mkdir $BUILD_DIR/open_blas
	fi

	# change to working directory
	cd $BUILD_DIR/open_blas

	# download openblas if we didn't already
	if [ ! -f v0.2.19.zip ]
	then
		wget http://github.com/xianyi/OpenBLAS/archive/v0.2.19.zip
	fi

	if [ ! -d OpenBlas-0.2.19]
	then
		unzip v0.2.19.zip
	fi
	
	cd OpenBLAS-0.2.19

	# build
	make USE_THREAD=$USE_THREAD
	make install PREFIX=$INSTALL_PREFIX

	cd $OLD_DIR
}

# LAPACK
#
# Usage: install_lapack BUILD_DIR INSTALL_PREFIX LIBOPENBLAS
#
# Installs lapack
# needs openblas at $LIBOPENBLAS
#
# Args:
# 	BUILD_DIR      (path) - path to build dir which we can use
# 	INSTALL_PREFIX (path) - path where to install to
# 	LIBOPENBLAS    (path) - path to libopenblas.a, defaults to INSTALL_PREFIX/lib/libopenblas.a

install_lapack() {

	BUILD_DIR=$1
	INSTALL_PREFIX=$2
	LIBOPENBLAS=$3
	OLD_DIR=$(pwd)

	if [ -z ${LIBOPENBLAS+x} ];
	then
		echo "INFO in install_lapack: LIBOPENBLAS not given, defaulting to INSTALL_PREFIX/lib/libopenblas.a"
		LIBOPENBLAS=$INSTALL_PREFIX/lib/libopenblas.a
	fi

	if [ ! -f $LIBOPENBLAS ]
	then
		echo "ERROR in install_lapack: Can't find libopenblas.a, exiting"
		exit 1
	fi

	if [ -z ${BUILD_DIR+x} ];
	then
		echo "ERROR in install_lapack: BUILD_DIR is not given, exiting."
		exit 1
	fi

	if [ ! -d $BUILD_DIR/lapack]
	then
		mkdir $BUILD_DIR/lapack
	fi

	cd $BUILD_DIR/lapack

	# check if we already downloaded lapack
	if [ ! -f lapack-3.6.1.tgz ]
	then
		# if not, download it 
		wget http://www.netlib.org/lapack/lapack-3.6.1.tgz
	fi

	# check if we already unpacked lapack
	if [ ! -d lapack-3.6.1]
	then
		# else unpack it
		tar -xzvf lapack-3.6.1.tgz
	fi

	cd lapack-3.6.1

	# Give correct paths to openblas
	cp make.inc.example make.inc
	sed -i 's!../../librefblas.a!'"$LIBOPENBLAS"'!g' make.inc
	sed -i 's!../../libcblas.a!'"$LIBOPENBLAS"'!g' make.inc
	ulimit -s 65000

	make
	cp */include/*.h $INSTALL_PREFIX/include/
	cp *.a $INSTALL_PREFIX/lib

	cd $OLD_DIR
}

# PLASMA
#
# Usage: install_lapack BUILD_DIR INSTALL_PREFIX
#
# Installs plasma
#
# Args:
# 	BUILD_DIR      (path) - path to build dir which we can use
# 	INSTALL_PREFIX (path) - path where to install to
# 	LIBOPENBLAS    (path) - path to libopenblas.a, defaults to INSTALL_PREFIX/lib/libopenblas.a
# 	LIBLAPACK      (path) - path to liblapack.a, default to INSTALL_PREFIX/lib/libopenblas.a
#       LAPACKE_DIR    (path) - path to lapack C interface - must be to the directory, not the lib itself. 
# 	                         Defaults to letting plasma downloading it.
install_plasma() {
	BUILD_DIR=$1
	INSTALL_PREFIX=$2
	LIBOPENBLAS=$3
	LIBLAPACK=$4
	LAPACKE_DIR=$5

	OLD_DIR=$(pwd)
	PLASMA_PREFIX=$BUILD_DIR/plasma/_build

	export PKG_CONFIG_PATH=/usr/lib/pkgconfig

	if [ -z ${BUILD_DIR+x} ];
	then
		echo "ERROR in install_plasma: BUILD_DIR is not given, exiting."
		exit 1
	fi

	if [ ! -d $BUILD_DIR/plasma]
	then
		mkdir $BUILD_DIR/plasma
	fi

	if [ ! -d $PLASMA_PREFIX ]
	then
		mkdir $PLASMA_PREFIX
	fi

	# if not (LIBOPENBLAS is set and is a file)
	if [ ! ( ( -z ${LIBOPENBLAS+x} )  -a -f $LIBOPENBLAS ) ]
	then
		# set it to its default
		LIBOPENBLAS=$INSTALL_PREFIX/lib/libopenblas.a
	fi

	# if not (LIBLAPACK is set and is a file)
	if [ ! ( ( -z ${LIBLAPACK+x} )  -a -f $LIBLAPACK ) ]
	then
		# set it to its default
		LIBLAPACK=$INSTALL_PREFIX/lib/liblapack.a
	fi

	# if not (LAPACKE_DIR is set and is a directory)
	if [ ! ( ( -z ${LAPACKE_DIR+x} )  -a -d $LAPACKE_DIR ) ]
	then
		# set it to its default
		LAPACKE_FLAG="--downlapc"
	else
		LAPACKE_FLAG="--lapclib=$LAPACKE_DIR"
	fi

	cd $BUILD_DIR/plasma

	# if we didn't download plasma already 
	if [ ! -f plasma-installer_2.8.0.tar.gz ]
	then
		# download it now
		wget http://icl.cs.utk.edu/projectsfiles/plasma/pubs/plasma-installer_2.8.0.tar.gz
	fi

	# if we didn't unpack plasma already
	if [ ! -d plasma-installer_2.8.0 ]
	then
		# unpack it
		tar -xzvf plasma-installer_2.8.0.tar.gz
	fi

	cd plasma-installer_2.8.0

	./setup.py --prefix=$PLASMA_PREFIX --blaslib=$LIBOPENBLAS --cblaslib=$LIBOPENBLAS --lapacklib=$LIBOPENBLAS --notesting $LAPACKE_FLAG
	cp $PLASMA_PREFIX/plasma/include/*.h $INSTALL_PREFIX/include
	cp $PLASMA_PREFIX/plasma/lib/*.a $INSTALL_PREFIX/lib/
}

#Create Makefile
install_makefile() {
	cp template_Makefile Makefile
	sed -i 's!{$INSTALL_PREFIX}!'"$INSTALL_PREFIX"'!g' $INSTALL_PREFIX/Makefile
}
