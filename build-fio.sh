#!/bin/bash

fiodir=fio
fiotar=fio-3.12
patch=fio-3.12-barrier.patch

pushd $fiodir
echo -n "Extracting fio sources...."
tar -zxf $fiotar.tgz 
echo "Done"

pushd $fiotar
echo "Applying patch"
patch -p1 < ../$patch

echo "Compile fio"
./configure
make

popd
popd

echo "Done."

