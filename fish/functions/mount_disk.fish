function mount_disk --description 'Mounts a disk selected with fzf and adjusts permissions'
    # Check for unmount flag
    if test "$argv[1]" = "-u"
        # List only mounted devices (where MOUNTPOINT is not empty)
        set -l selection (lsblk -p -l -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL | awk 'NR==1 || $4 != ""' | fzf --header="Select the device to unmount" --reverse)

        if test -z "$selection"
            echo "Cycle aborted."
            return 1
        end

        # Extract device path (first column)
        set -l device (echo $selection | awk '{print $1}')

        echo "Unmounting $device..."
        if sudo umount $device
            echo "Unmount successful."
        else
            echo "Error during unmount process."
            return 1
        end
        return 0
    end

    # 1. List devices and select
    set -l selection (lsblk -p -l -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL | fzf --header="Select the device to mount" --reverse)

    if test -z "$selection"
        echo "Cycle aborted."
        return 1
    end

    # Extract device path (first column)
    set -l device (echo $selection | awk '{print $1}')

    # 2. Ask for mount point
    read -P "Enter folder name in /mnt/ (e.g., disk): " mount_name
    set -l mount_path "/mnt/$mount_name"

    if test -z "$mount_name"
        echo "Invalid folder name. Cycle aborted."
        return 1
    end

    # 3. Execute operations
    echo "Mounting $device at $mount_path..."

    if sudo mkdir -p $mount_path && sudo mount $device $mount_path
        echo "Mount successful. Adjusting permissions..."
        sudo chown -R $USER:users $mount_path
        echo "Operation completed."
    else
        echo "Error during mount process."
        return 1
    end
end
