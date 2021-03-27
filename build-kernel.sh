#!/bin/bash

kerneldir=linux-kernel
kerneltar=linux-kernel-5.0.0-16.17
kernel01dir=linux-kernel-5.0.0-16.17-nvmecint
kernel02dir=linux-kernel-5.0.0-16.17-nvmecint-rocks
patch01=cinterrupts-01-basis.patch
patch02=cinterrupts-02-rocks-addon.patch
config=config-file

pushd $kerneldir

rm -rf $kernel01dir
rm -rf $kernel02dir

# first extract and compile kernel for microbenchamrks

echo -n "Extracting kernel...."
cat $kerneltar.tgz-part-* > $kerneltar.tgz
tar -zxf $kerneltar.tgz 
echo "Done"

mv $kerneltar $kernel01dir

pushd $kernel01dir
echo "Applying patch01"
patch -p1 < ../$patch01
cp ../$config .config

echo "Start compilation"
make oldconfig
make bzImage -j 28
make modules -j 28
sudo make modules_install -j 28
sudo make install
popd

echo;echo;echo

# now extract and compile kernel for rocksdb

echo -n "Extracting kernel...."
cat $kerneltar.tgz-part-* > $kerneltar.tgz
tar -zxf $kerneltar.tgz 
echo "Done"

mv $kerneltar $kernel02dir

pushd $kernel02dir
echo "Applying patch01 and patch02"
patch -p1 < ../$patch01
patch -p1 < ../$patch02
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
echo
echo "To boot cintereupts kernel for microbenchamrks run:"
echo "sudo grub-reboot \"Ubuntu, with Linux 5.0.8-nvmecint\""
echo "sudo reboot"
echo 
echo "To boot cintereupts kernel for macrobenchamrks run:"
echo "sudo grub-reboot \"Ubuntu, with Linux 5.0.8-nvmecint-rocks\""
echo "sudo reboot"
echo
echo "For now set next boot entry for microbenchmarks kernel"
echo -n "Set grub to boot Linux 5.0.8-nvmecint kernel..."
sudo grub-reboot "Ubuntu, with Linux 5.0.8-nvmecint"
echo "Done."

echo "You can reboot the machine now."

