#!/bin/bash

fiodir=fio
fiotar=fio-3.13
patch=fio_barrier.patch

pushd $fiodir
echo -n "Extracting fio sources...."
tar -zxf $fiotar.tgz 
echo "Done"

pushd $fiotar
echo "Applying patch"
patch -p1 < ../$patch

echo "Compile fio"
make

popd
popd

echo "Done."

