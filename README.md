## Calibrated Interrupts
This repository contains instructions and source code for compiling and
reproducing results in the Calibrated Interrupts (cinterrupts) paper,
to appear in OSDI '21 (see the paper PDF in the top-level of this repository).

### Evaluation instructions
At the end of this document, we describe how to compile and install
the evaluation environment, should the evaluator choose to do so.
However, due to needing the cinterrupts custom kernel, we have set up
an environment for the evaluators on our machine.

#### Accessing the evaluation environment
Our system works closely with real hardware and reproduction
of our results requires a low latency Intel Optane NVMe SSD (or similar).
In addition, we wrote our scripts with an assumption that underlying SSD
is connected to a NUMA node `#1` which hosts cores `1,3,5,7`.
Different configuration will require updating our scripts accordingly.
Furthermore, in our experience, different CPUs and machine setups
require different macrobenchmark (application) configurations
to saturate the CPU.
This is why we provide evaluators with an access to our setup with
Intel Optane NVMe SSD installed and preconfigured building environment.

Please contact authors how to access this setup remotely.
(Account username/password and machine IPs are privileged information
that we prefer to send out-of-band.)

### Content of the repository
* `linux-kernel` directory with Linux kernel sources and cinterrupts patch
* `linux-kernel/cinterrupts-01-basis.patch` device emulation and nvme driver
* `linux-kernel/cinterrupts-02-rocks-addon.patch` addition for multi queue support for rocksdb and other macrobenchmarks
* `linux-kernel/linux-kernel-5.0.0-16.17.tgz-part-a[abcd]` split archive of the Linux vanilla kernel ver 5.0.0-16.17
* `linux-kernel/config-file` config file used for our kernel compilation
* `build-kernel.sh` script to extract Linux kernels source, apply the cinterrupts patch and compile the kernel
* `fio` directory with fio 3.12 sources and cinterrupt patch for fio
* `fio/fio-3.12.tgz` sources of original fio version 3.12
* `fio/fio-3.12-barrier.patch` patch with cinterrupts support in fio + additional statistics added to fio as we used these in our results analysis
* `build-fio.sh` script to extract fio source, apply cinterrupts patch and compile the fio
* `utils` directory with scripts we use in our project
* `fig5` directory with scripts to reproduce Figure 5 in the paper, cd to `fig5` and run `make-all.sh`, see `fig5.pdf`
* `fig6` directory with scripts to reproduce Figure 6 in the paper, cd to `fig6` and run `make-all.sh`, see `fig6.pdf`
* `fig7` directory with scripts to reproduce Figure 7 in the paper, cd to `fig7` and run `make-all.sh`, see `fig7.pdf`
* `fig10` directory with scripts to reproduce Figure 10 in the paper, cd to `fig10` and run `make-all.sh`, see `fig10.pdf`
* `fig14` directory with scripts to reproduce Figure 14 in the paper, cd to `fig14` and run `make-all.sh`, see `fig14.pdf`
* `fig15` directory with scripts to reproduce Figure 15 in the paper, cd to `fig15` and refer to `README`
* `fig16` directory with scripts to reproduce Figure 16 in the paper, cd to `fig16` and refer to `README`
* `rocksdb` directory with `cint.patch` and RocksDB v6.4.6 sources
* `kvell` directory with KVell sources
* `tab3` directory with scripts to reproduce Table 3 in the paper, cd to `tab3` and refer to `README`
* `tab5+fig17` directory with scripts to reproduce Table 5 and Figure 17 in the paper, cd to `tab5+fig17` and refer to `README`


### Compilation instructions
We highly recommend that you build on Ubuntu 16.04.
To build the custom cint kernel, you will need any dependencies
required for the Linux kernel. These include libssl-dev, bison,
flex, and optionally dh-exec. If there is a compilation error,
it is likely because one of these packages is missing.

Run `build-kernel.sh` in the top-level directory of this repository.
This will build and install our custom kernels for micro and macro
benchmarks. You will then need to run this script once. To simplify artifact
testing we already ran this script which extracted, compiled and installed
our kernels into `linux-kernel/linux-kernel-5.0.0-16.17-nvmecint` and
`linux-kernel/linux-kernel-5.0.0-16.17-nvmecint-rocks` directories.

We install two kernels:
* `5.0.8-nvmecint` is used to test microbenchmarks (fig5,fig6,fig7,fig10,fig14), it emulates a single SQ/CQ pair.
* `5.0.8-nvmecint-rocks` is used to test multithreaded macrobenchmarks (fig15,fig16,tab3,tab5+fig17),
   same as above with the addition of multiple SQ/CQ pairs emulation.

To boot into `5.0.8-nvmecint` kernel run:
```
$> sudo grub-reboot "Ubuntu, with Linux 5.0.8-nvmecint"
$> sudo reboot
```
To boot into `5.0.8-nvmecint-rocks` kernel run:
```
$> sudo grub-reboot "Ubuntu, with Linux 5.0.8-nvmecint-rocks"
$> sudo reboot
```


When kernel is loaded the driver is ready. If you modify the driver and
need to compile it then run:

```
$> cd linux-kernel/linux-kernel-5.0.0-16.17-nvmecint
$> sh nvme-make.sh

```

After that, to switch between different NVMe interrupt emulations and
the original driver, you simply need to unload and load the correct
nvme driver with relevant parameters:

```
$> cd linux-kernel/linux-kernel-5.0.0-16.17-nvmecint
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

To change the parameters edit config files in form `nvme-$(hostname)-$(mode).conf`, for example:

```
$> cd linux-kernel/linux-kernel-5.0.0-16.17-nvmecint
$> vim nvme-$(hostname).conf            # params for the cinterrupts driver
$> vim nvme-$(hostname)-clean.conf      # params for the original nvme driver
$> vim nvme-$(hostname)-emul.conf       # params for the emulated nvme device driver

```


### Installation and Setup Instructions
After booting into this custom kernel, compile fio benchmark.
Run `build-fio.sh` in the top-level directory of this repository.
Path to fio from the top-level directory: `fio/fio-3.12/fio`
If you can successfully run fio, you are ready!

[//]: # (Now you can run the following experiments:)
[//]: # (TODO: decribe each experiment)

### Running benchmarks
You should compile the following applications,
which are applications we modified for cinterrupts.

- FIO (just run `build-fio.sh` script in the top-level directory)
- RocksDB (just run `build-rocksdb.sh` in the top-level directory)
- KVell (just run `build-kvell.sh` in the top-level directory)

#### Reproducing each figure
In the figX/ subdirectories, we have scripts and instructions for
reproducing the key figures in our paper, e.g., `fig5` directory
contain all scripts needed to reproduce `Figure 5` in the paper.
Enter to a figX directory and run `make-all.sh`.
See `figX.pdf` with test results, but please check README for
each directory to confirm output. For example, results for tables
in the paper  are
stored directly in *.out files.

> Pay attention, for microbenchmarks,
> our scripts run each benchmark 10 times, 60 seconds each run.
> Since there are multiple flavours of each test the total runtime
> can be very long. To reduce total runtime evaluators can
> change `runtime` and `runs` variables in the test scripts.
>
> For macrobenchmarks, experiments can also take a while to run (up to 45 min)
> as they run each benchmark 5 times. Consider using tmux to
> make sure the benchmark continues to run even if ssh connection is broken.

