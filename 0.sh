#!/bin/bash

# VirtualBox Setup
# VM config: 1cpu+512MB+256GB (will override first two with vagrant)
# General->Advanced: bidirectional + bidirectional
# System->Processor: PAE
# Display->Video: enough for UHD
# Storage: add xubuntu CD + harddisk type SSD
# Network->Adapter 1->NAT + virtio-net

CPUS=1                          #small base
DISKSIZEGB=${2:-80}
ISO=$1
MEM=768                         #small base (512 is too small for desktop)
VBM=VBoxManage
VRAM=$((2+3840*2160*4/1048576)) #UHD + 2

if [ ! -f "$1" ]; then

    cat <<EOM
Usage:
yourself@host\$ ./0.sh iso-path [disk-size-in-GB (default $DISKSIZEGB)]
EOM

else

    # register VM
    read -ep 'VM name (try "XU64Base"): ' \
         $([ $BASH_VERSINFO -ge 4 ] && echo '-i XU64Base') \
         VMNAME
    VMUUID=$($VBM createvm --name "$VMNAME" --ostype Ubuntu_64 --register |
                    gawk '/^UUID:/{print $2}')
    echo 'VM registered.'

    # configure VM
    $VBM modifyvm $VMUUID \
         --accelerate2dvideo off \
         --accelerate3d on `#https://www.virtualbox.org/ticket/10250` \
         --audio coreaudio \
         --audiocontroller ac97 \
         --clipboard bidirectional \
         --cpus $CPUS \
         --draganddrop bidirectional \
         --memory $MEM \
         --mouse usbtablet \
         --nic1 nat \
         --nictype1 virtio \
         --pae on \
         --rtcuseutc on \
         --usb on \
         --usbehci on \
         --vram $VRAM \
         `#end`

    # configure IDE and attach Xubuntu iso
    $VBM storagectl $VMUUID \
         --add ide \
         --bootable on \
         --controller PIIX4 \
         --hostiocache on \
         --name IDE \
         --portcount 2 \
         `#end`
    $VBM storageattach $VMUUID \
         --device 0 \
         --medium "$ISO" \
         --port 1 \
         --storagectl IDE \
         --type dvddrive \
         `#end`

    # attach Guest Additions iso
    # https://www.virtualbox.org/ticket/13040
    $VBM storageattach $VMUUID \
         --device 1 \
         --medium emptydrive \
         --port 1 \
         --storagectl IDE \
         --type dvddrive \
         `#end`
    $VBM storageattach $VMUUID \
         --device 1 \
         --medium additions \
         --port 1 \
         --storagectl IDE \
         --type dvddrive \
         `#end`

    # configure SATA and attach new hdd
    VMPREFIX=$($VBM showvminfo $VMUUID --machinereadable |
                      gawk -F = '/^CfgFile=/{print $2}' |
                      xargs dirname)
    DISKNAME=$VMPREFIX/$VMNAME.vdi
    $VBM createhd --filename "$DISKNAME" \
         --format VDI \
         --sizebyte $(($DISKSIZEGB * 1024 * 1024 * 1024)) \
         `#end` > /dev/null
    $VBM storagectl $VMUUID \
         --add sata \
         --bootable on \
         --controller IntelAHCI \
         --hostiocache off \
         --name SATA \
         --portcount 1 \
         `#end`
    $VBM storageattach $VMUUID \
         --device 0 \
         --medium "$DISKNAME" \
         --nonrotational on \
         --port 0 \
         --storagectl SATA \
         --type hdd \
         `#end`
    echo 'Disk image created.'

    # instructions to continue
    cat <<EOM
VM created.

Start the VM to run the Xubuntu installer. Notes:
1. No need to "Download updates while installing" (we will dist-upgrade later).
2. Enable "Install this third-party software" (if you want a nice desktop env).
3. Use LVM, always.
4. name          = vagrant
   computer name = XU64    (no base!)
   username      = vagrant (don't worry, we will create your account later)
   password      = vagrant
5. At "Installation Complete", click "Restart Now".
6. A minute later you will see gibberish. Use VirtualBox to shutdown the VM.
   (The message "Please remove installation media and close the tray (if any)
    then press ENTER:" mixed inside other shutdown messages.)
7. Take a snapshot of the VM.

Enjoy!
EOM

fi
