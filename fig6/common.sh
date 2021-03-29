rmmod=/sbin/rmmod
insmod=/sbin/insmod
modprobe=/sbin/modprobe

function unload_driver {
    echo
    echo "Going to unload nvme driver"
    sudo pkill -9 fio
    sleep 5
    sudo umount /dev/nvme0n1p1 2>/dev/null
    sudo $rmmod nvme 2>/dev/null
    sudo $rmmod nvme-emul 2>/dev/null
    sudo $rmmod nvme-clean 2>/dev/null
    sudo rm -f /dev/nvme* 2>/dev/null
}

function check_and_tryagain {
    local time=30
    local rounds=5

    while (lsmod | grep nvme | grep -q -v core); do

	[ "$rounds" -eq 0 ] && { echo "Can't unload driver, exiting."; exit 1; }

        # It is possible for a request to arrive after the poller was shutdown.
	# In this case request will be completed by the timer after 30 seconds.
        echo "Driver is stuck, wait $time sec and try again."
    	sleep $time
	unload_driver

	rounds=`expr $rounds - 1`

    done
    # now we can remove nvme_core
    sudo $rmmod nvme_core 2>/dev/null
    echo "Driver unloaded"
}

function load_driver {
    local driver="$drv_dir"/"$1"
    local params="$2"
    echo "Loading nvme driver $driver"
    echo "Params: "$params""
    sudo $modprobe nvme_core || { echo "Can't load nvme_core"; lsmod | grep nvme; exit 1; }
    sudo $insmod $driver $params || { echo "Can't load $driver"; lsmod | grep nvme; exit 1; }
    sleep 5
    echo "Loaded"
}


