#!/bin/bash

rocksdir=rocksdb
rockstar=v6.4.6
rocks_srcdir=rocksdb-6.4.6
patch=cint.patch

pushd $rocksdir
echo -n "Extracting rocksdb sources...."
tar -zxf ${rockstar}.tar.gz
echo "Done"

pushd ${rocks_srcdir}
echo "Applying patch"
patch -p1 < ../$patch

echo "Compile rocksdb"

popd
popd

echo "Done."

