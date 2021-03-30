#!/bin/bash

kvelldir=kvell

pushd $kvelldir
make clean
make
popd

echo "Done."

