#!/bin/bash

kerneldir=linux-kernel
kerneltar=linux-kernel-5.0.0-16.17
patch=cinterrupts.patch
config=config-file

pushd $kerneldir
echo -n "Extracting kernel...."
tar -zxf $kerneltar.tgz 
echo -n "Done"

pushd $kerneltar
echo "Applying patch"
patch -p1 < ../$patch
cp ../$config .config

echo "Start compilation"
make oldconfig
make bzImage -j 28
make modules -j 28
sudo make modules_install -j 28
sudo make install

popd
popd

echo "Done."
echo -n "Set grub to boot Linux 5.0.8-nvmecint kernel..."
sudo grub-reboot "Ubuntu, with Linux 5.0.8-nvmecint"
echo "Done."

echo "You can reboot the machine now."
