#!/bin/bash
sudo umount /dev/nvme0n1p3
sudo umount /dev/nvme0n1p2
sudo umount /dev/nvme0n1p1

sudo modprobe -r nvme nvme_emul nvme_core
sleep 3
ls -al /dev/nvme*
lsmod
    
sudo modprobe nvme irq_poller_cpu=9,11,13,15 irq_poller_target_cpu=1,3,5,19 irq_poller_target_queue_id=15,16,17,24 irq_poller_delay=15 irq_poller_max_thr=32 empathetic=Y
sleep 2
ls -al /dev/nvme*

sudo mount /dev/nvme0n1p3 /scratch0
sudo mkdir /scratch0/kvell
sudo rm -f /scratch0/kvell/*

sudo ../kvell/main 0 $1 $2

echo "Done with load"
