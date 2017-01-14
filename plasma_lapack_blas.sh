#!/bin/bash


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

	if [ -z ${BUILD_DIR+x} ]
	then
		echo "Error in install_openblas: BUILD_DIR is empty"
		exit 1
	fi

	if [ ! -d $BUILD_DIR/open_blas ]
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

	if [ ! -d OpenBLAS-0.2.19 ]
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

	if [ -z ${LIBOPENBLAS+x} ]
	then
		echo "INFO in install_lapack: LIBOPENBLAS not given, defaulting to INSTALL_PREFIX/lib/libopenblas.a"
		LIBOPENBLAS=$INSTALL_PREFIX/lib/libopenblas.a
	fi

	if [ ! -f $LIBOPENBLAS ]
	then
		echo "ERROR in install_lapack: Can't find libopenblas.a, exiting"
		exit 1
	fi

	if [ -z ${BUILD_DIR+x} ]
	then
		echo "ERROR in install_lapack: BUILD_DIR is not given, exiting."
		exit 1
	fi

	if [ ! -d $BUILD_DIR/lapack ]
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
	if [ ! -d lapack-3.6.1 ]
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
	cp */include/*.h $INSTALL_PREFIX/include
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
#       LAPACKE_DIR    (path) - path to lapack C interface - must be to the directory, not the lib itself. 
# 	                         Defaults to letting plasma downloading it.
# 	LIBOPENBLAS    (path) - path to libopenblas.a, defaults to INSTALL_PREFIX/lib/libopenblas.a
# 	LIBLAPACK      (path) - path to liblapack.a, default to INSTALL_PREFIX/lib/libopenblas.a
#
install_plasma() {
	BUILD_DIR=$1
	INSTALL_PREFIX=$2
	LAPACKE_DIR=$3
	LIBOPENBLAS=$4
	LIBLAPACK=$5

	OLD_DIR=$(pwd)
	PLASMA_PREFIX=$BUILD_DIR/plasma/_build

	export PKG_CONFIG_PATH=/usr/lib/pkgconfig

	if [ -z ${BUILD_DIR+x} ]
	then
		echo "ERROR in install_plasma: BUILD_DIR is not given, exiting."
		exit 1
	fi

	if [ ! -d $BUILD_DIR/plasma ]
	then
		mkdir $BUILD_DIR/plasma
	fi

	if [ ! -d $PLASMA_PREFIX ]
	then
		mkdir $PLASMA_PREFIX
	fi

	# if not (LIBOPENBLAS is set and is a file)
	if [ ! -z ${LIBOPENBLAS+x} ]
	then
		# set it to its default
		LIBOPENBLAS=$INSTALL_PREFIX/lib/libopenblas.a
	fi

	# if not (LIBLAPACK is set and is a file)
	if [ ! -z ${LIBLAPACK+x} ]
	then
		# set it to its default
		LIBLAPACK=$INSTALL_PREFIX/lib/liblapack.a
	fi

	echo $LAPACKE_DIR
	LAPACKE_FLAG="--downlapc"
	# if not (LAPACKE_DIR is set and is a directory)
	if [ ! -z ${LAPACKE_DIR+x} ]
	then
		LAPACKE_FLAG="--lapclib=$LAPACKE_DIR"
	fi

	echo $LAPACKE_FLAG

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

	echo "./setup.py --prefix=$PLASMA_PREFIX --blaslib=$LIBOPENBLAS --cblaslib=$LIBOPENBLAS --lapacklib=$LIBLAPACK --notesting $LAPACKE_FLAG"
	./setup.py --prefix=$PLASMA_PREFIX --blaslib=$LIBOPENBLAS --cblaslib=$LIBOPENBLAS --lapacklib=$LIBLAPACK $LAPACKE_FLAG --notesting 
	cp $PLASMA_PREFIX/include/*.h $INSTALL_PREFIX/include
	cp $PLASMA_PREFIX/lib/*.a $INSTALL_PREFIX/lib/

	cd $OLD_DIR
}


# PAPI
#
# Usage: install_papi BUILD_DIR INSTALL_PREFIX
#
# Installs PAPI
#
# Args:
# 	BUILD_DIR      (path) - path to build dir which we can use
# 	INSTALL_PREFIX (path) - path where to install to

install_papi() {

	BUILD_DIR=$1
	INSTALL_PREFIX=$2
	OLD_DIR=$(pwd)

	if [ -z ${BUILD_DIR+x} ]
	then
		echo "Error in install_papi: BUILD_DIR is empty"
		exit 1
	fi

	if [ ! -d $BUILD_DIR/papi_install ]
	then
		mkdir $BUILD_DIR/papi_install
	fi

	# change to working directory
	cd $BUILD_DIR/papi_install

	# download PAPI if we didn't already
	if [ ! -f papi-5.5.1.tar.gz ]
	then
		wget http://icl.utk.edu/projects/papi/downloads/papi-5.5.1.tar.gz
	fi

	if [ ! -d papi-5.5.1 ]
	then
		tar -xvzf papi-5.5.1.tar.gz
	fi
	
	cd papi-5.5.1/src

	# build
	./configure
	make
	make test
	make PREFIX=$INSTALL_PREFIX

	cp *.h $INSTALL_PREFIX/include/
	cp *.a $INSTALL_PREFIX/lib

	cd $OLD_DIR
}


# Usage: install_makefile INSTALL_PREFIX
#
# Args:
# 	INSTALL_PREFIX (path) - path where lib and include live in and have all necessary libraries
#
# Creates Makefile
install_makefile() {
	INSTALL_PREFIX=$1
	cp template_Makefile Makefile
	sed -i 's!{$INSTALL_PREFIX}!'"$INSTALL_PREFIX"'!g' $INSTALL_PREFIX/Makefile
}

WORKING_DIR=$(pwd)

if [ -z ${BUILD_DIR+x} ]
then
	BUILD_DIR=./_build
fi
BUILD_DIR=$(readlink -f $BUILD_DIR)

if [ -z ${INSTALL_PREFIX+x} ]
then 
	echo "Please provide and install prefix in the env INSTALL_PREFIX"
	echo "INSTALL_PREFIX is unset, aborting installation..."
	exit 1
fi
INSTALL_PREFIX=$(readlink -f $INSTALL_PREFIX)

if [ ! -d $BUILD_DIR ]
then
	mkdir $BUILD_DIR
	__build_dir_created=yes
fi
BUILD_DIR=$(readlink -f $BUILD_DIR)

cd $BUILD_DIR
 
if [ ! -d $INSTALL_PREFIX ]
then
	mkdir $INSTALL_PREFIX
fi

if [ ! -d $INSTALL_PREFIX/lib ]
then
	mkdir $INSTALL_PREFIX/lib
fi

if [ ! -d $INSTALL_PREFIX/include ]
then
	mkdir $INSTALL_PREFIX/include
fi

echo "Installing openblas"
install_openblas $BUILD_DIR $INSTALL_PREFIX 0
echo "Installing lapack"
install_lapack $BUILD_DIR $INSTALL_PREFIX
echo "Installing plasma"
install_plasma $BUILD_DIR $INSTALL_PREFIX $BUILD_DIR/lapack/lapack-3.6.1/liblapacke.a
echo "Installing PAPI"
install_papi $BUILD_DIR $INSTALL_PREFIX
echo "Generating makefile"
install_makefile
