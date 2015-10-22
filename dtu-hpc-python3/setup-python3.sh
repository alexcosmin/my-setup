#!/bin/sh

#PBS -N setup-python3
#PBS -l walltime=01:30:00
#PBS -l nodes=1:ppn=1:gpus=1
#PBS -j oe
#PBS -o setup-python3.log

# Stop on error
set -e

# Set $HOME if running as a qsub script
if [ -z "$PBS_O_WORKDIR" ]; then
    export HOME=$PBS_O_WORKDIR
fi

# Retry wget errors (20 times) (e.q. 504)
# sourceforge in particular is not very stable
function wgetretry {
    wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 ||
    wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1 || wget $1
}

# Load already installed software
module load python3
module load gcc
module load cuda
module load qt
module load boost

# Setup to use gnu compiler and hide warnings
export CC='gcc -w'
export CXX='g++ -w'

# Setup cuda path for clBLAS
export CUDA_PATH=/opt/cuda/current

# Use HOME directory as base
cd $HOME

# Setup virtual env
export PYTHONPATH=
pyvenv ~/stdpy3 --copies
source ~/stdpy3/bin/activate

#
# Install basic python math
#
pip3 install -U numpy
pip3 install -U scipy

#
# Install matplotlib with Qt4 and basemap enabled
#

# Install sip (dependency for PyQt4)
wgetretry http://sourceforge.net/projects/pyqt/files/sip/sip-4.16.6/sip-4.16.6.zip
unzip -q sip-4.16.6.zip
cd sip-4.16.6
python3 configure.py
make
make install
cd $HOME
rm -rf sip-4.16.6*

# Install PyQt4 (optional backend for matplotlib)
wgetretry http://sourceforge.net/projects/pyqt/files/PyQt4/PyQt-4.11.3/PyQt-x11-gpl-4.11.3.tar.gz
tar -xf PyQt-x11-gpl-4.11.3.tar.gz
cd PyQt-x11-gpl-4.11.3
python3 configure.py --confirm-license
make
make install
cd $HOME
rm -rf PyQt-x11-gpl-4.11.3*

# Install matplotlib
pip3 install -U matplotlib

# Install basemap (matplotlib extension)
wgetretry http://downloads.sourceforge.net/project/matplotlib/matplotlib-toolkits/basemap-1.0.7/basemap-1.0.7.tar.gz
tar -xf basemap-1.0.7.tar.gz 
cd basemap-1.0.7
cd geos-3.3.3
./configure --prefix=$HOME
make
make install
cd ..
python3 setup.py install
cd $HOME
rm -rf basemap-1.0.7*

#
# Install data science
#
pip3 install -U scikit-learn
pip3 install -U pandas

#
# Install pyOpenCL
#

# Install mako (optional dependency for pyopencl)
pip3 install -U mako

# Install pyOpenCL
wgetretry https://pypi.python.org/packages/source/p/pyopencl/pyopencl-2015.1.tar.gz
tar -xf pyopencl-2015.1.tar.gz
cd pyopencl-2015.1
python3 configure.py \
    --cl-inc-dir=$CUDA_PATH/include \
    --cl-lib-dir=$CUDA_PATH/lib \
    --cl-libname=OpenCL
make install
cd $HOME
rm -rf pyopencl-2015.1*

#
# Install theano
#

# Instal pydot (optional theano dependencies)
pip3 install https://bitbucket.org/prologic/pydot/get/ac76697320d6.zip
patch -f stdpy3/lib/python3.4/site-packages/dot_parser.py \
<<EOF
--- a/stdpy3/lib/python3.4/site-packages/dot_parser.py
+++ b/stdpy3/lib/python3.4/site-packages/dot_parser.py
@@ -25,8 +25,9 @@
 from pyparsing import ( nestedExpr, Literal, CaselessLiteral, Word, Upcase, OneOrMore, ZeroOrMore,
     Forward, NotAny, delimitedList, oneOf, Group, Optional, Combine, alphas, nums,
     restOfLine, cStyleComment, nums, alphanums, printables, empty, quotedString,
-    ParseException, ParseResults, CharsNotIn, _noncomma, dblQuotedString, QuotedString, ParserElement )
+    ParseException, ParseResults, CharsNotIn, dblQuotedString, QuotedString, ParserElement )

+_noncomma = "".join([c for c in printables if c != ","])

 class P_AttrList:
EOF

# Install libgpuarray (optional theano dependencies)
# Note the HPC version of check.h is old, so ck_assert_ptr_ne is not defined
# since it is just the test files. Just remove the test.
git clone https://github.com/Theano/libgpuarray.git
cd libgpuarray
patch -f tests/check_array.c \
<<EOF
--- check_array.c
+++ check_array.c
@@ -57,7 +57,6 @@
   if (dev == -1)
     ck_abort_msg("Bad test device");
   ctx = ops->buffer_init(dev, 0, NULL);
-  ck_assert_ptr_ne(ctx, NULL);
 }

 void teardown(void) {
EOF
mkdir Build && cd Build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=~/
make
make install
cd $HOME
rm -rf libgpuarray

# Install theano
pip3 install theano

# Configure theano 
cat > .theanorc <<EOF
[global]
device = gpu
floatX = float32

[cuda]
root = /opt/cuda/current

[nvcc]
flags = -arch=sm_30
EOF

# Install lasagne (development version)
pip3 install git+https://github.com/Lasagne/Lasagne.git

#
# Install h5py and netCDF4-python
#

# Install HDF5 (netCDF4 dependency) 
wgetretry http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.15-patch1.tar.gz
tar -xf hdf5-1.8.15-patch1.tar.gz
cd hdf5-1.8.15-patch1
./configure --prefix=$HOME --enable-shared --enable-hl
make
make install
cd $HOME
rm -rf hdf5-1.8.15-patch1*

# Install h5py
pip3 install Cython
pip3 install h5py

# Install netCDF4 (netCDF4-python dependency) 
wgetretry ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.3.3.1.tar.gz
tar -xzf netcdf-4.3.3.1.tar.gz
cd netcdf-4.3.3.1
./configure --enable-netcdf-4 --enable-dap --enable-shared --prefix=$HOME
make
make install
cd $HOME
rm -rf netcdf-4.3.3.1*

# Install netCDF4-python
pip3 install netcdf4

# DONE
cat <<EOF
####################################
##                                ##
##       python3 installed        ## 
##                                ##
####################################
EOF
