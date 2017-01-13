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
