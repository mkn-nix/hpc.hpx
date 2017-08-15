#!/usr/bin/env bash

set -e

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ -z "$(which cmake)" ] && echo "cmake is required to build viennacl" && exit 1;
[ -z "$(which mkn)" ]   && echo "mkn is required to build viennacl" && exit 1;

mkdir -p inst/lib inst/include

GIT_URL="https://github.com/STEllAR-GROUP/hpx"
GIT_BNC="master"
GIT_OPT="--depth 1"

[ -z "$HPX_WITH_MALLOC" ] && HPX_WITH_MALLOC=system

# initialise dependencies
mkn clean -p dep

MKN_CXXR="-O2 -fPIC"
MKN_CXXR=${CXXFLAGS:-$MKN_CXXR}
MKN_REPO="$(mkn -G MKN_REPO)"
VER_BOOST="$(mkn -G org.boost.version)"
VER_HWLOC="$(mkn -G ompi.hwloc.version)"

THREADS="$(nproc --all)"

[ ! -d "$CWD/hpx" ] && git clone $GIT_OPT $GIT_URL -b $GIT_BNC hpx --recursive

KLOG=3 mkn clean build -dtSa "${MKN_CXXR[@]}"

mkdir -p $CWD/hpx/build

pushd $CWD/hpx/build
read -r -d '' CMAKE <<- EOM || echo "running cmake"
    cmake -DBOOST_ROOT=$MKN_REPO/org/boost/$VER_BOOST/b 
          -DHWLOC_ROOT=$MKN_REPO/ompi/hwloc/$VER_HWLOC/inst
          -DHPX_WITH_MALLOC=$HPX_WITH_MALLOC 
          -DCMAKE_INSTALL_PREFIX=$CWD/inst 
          -DCMAKE_BUILD_TYPE=Release ..
EOM
$CMAKE
make -j$THREADS
make install
popd

echo "Running test"
$CWD/inst/bin/hello_world
echo "Finished successfully"
exit 0
