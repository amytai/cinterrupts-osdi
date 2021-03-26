## Calibrated Interrupts
This repository contains instructions and source code for compiling and reproducing results in the Calibrated Interrupts paper, to appear in OSDI '21 (see the paper PDF in the top-level of this repository).

### Evaluation instructions
At the end of this document, we describe how to compile and install the evaluation environment, should the evaluator choose to do so.
However, due to needing the cinterrupts custom kernel, we have set up an environment for the evalutors on our machines.

#### Accessing the evaluation environment
TODO: information on how to access the machines.

#### Reproducing each figure
In the XXX/ subdirectory, we have scripts and instructions for reproducing the key figures in our paper.


### Compilation instructions
We highly recommend that you build on Ubuntu 16.04.
To build the custom cint kernel, you will need any dependencies required for the Linux kernel.
These include libssl-dev, bison, flex, and optionally dh-exec.
If there is a compilation error, it is likely because one of these packages is missing.

Run `build-kernel.sh` in the top-level directory of this repository.
This will build and install this custom kernel in the normal places,
i.e. /boot and update grub. The name of the kernel image
will be 5.0.8-nvmecint. You will then need to reboot into this kernel,
which is only necessary the first time.

When kernel is loaded the driver is ready. If you modify driver and
need to compile only the driver then run:


```
$> cd linux-kernel/linux-kernel-5.0.0-16.17
$> sh nvme-make.sh

```

After that, to switch between different NVMe interrupt emulations and
the original driver, you simply need to unload and load the correct
NVMe module with relevant parameters:

```
$> cd linux-kernel/linux-kernel-5.0.0-16.17
$> sh ./nvme-reload.sh our-sol
$>
$> sh ./nvme-reload.sh
Usage: ./nvme-reload.sh {orig|emul|our-sol}

     orig    -- original nvme driver, for-bare-metal tests
     emul    -- emulation of the original nvme driver on a side core
     emul-100-32 -- emulation of the original nvme driver with 100 usec and 32 thr aggregation params
     our-sol -- side-core emulation of our nvme prototype with URGENT and BARRIER flags
     alpha   -- side-core emulation of our nvme prototype, only adaptive coalescing
     alpha0  -- side-core emulation of our nvme prototype, without any thresholds (new baseline0)

```

To change the parameters edit the following config files:
```
$> cd linux-kernel/linux-kernel-5.0.0-16.17
$> vim nvme-$(hostname).conf            # params for the cinterrupts driver
$> vim nvme-$(hostname)-clean.conf      # params for the original nvme driver
$> vim nvme-$(hostname)-emul.conf       # params for thenvme driver of emulated device

```


### Installation and Setup Instructions
After booting into this custom kernel, you can run the following experiments:

TODO

If you can successfully run FIO, you are ready!

### Running benchmarks
You are welcome to clone and compile the following applications, which are applications we modified for cinterrupts.

- FIO
- RocksDB
- KVell
