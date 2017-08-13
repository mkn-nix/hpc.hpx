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
LOC_HWLOC="$(mkn -G hwloc.location)"

THREADS="$(nproc --all)"

[ ! -d "$CWD/v" ] && git clone $GIT_OPT $GIT_URL -b $GIT_BNC v --recursive

KLOG=3 mkn clean build -dtSa "${MKN_CXXR[@]}"

mkdir -p $CWD/v/build
pushd $CWD/v/build

read -r -d '' CMAKE <<- EOM || echo "running cmake"
    cmake -DBOOST_ROOT=$MKN_REPO/org/boost/$VER_BOOST/b 
          -DHWLOC_ROOT=$LOC_HWLOC 
          -DHPX_WITH_MALLOC=$HPX_WITH_MALLOC 
          -DCMAKE_INSTALL_PREFIX=$CWD/inst 
          -DCMAKE_BUILD_TYPE=Release ..
EOM

echo $CMAKE
$CMAKE

make -j$THREADS
make install

popd

echo "Finished successfully"
exit 0
