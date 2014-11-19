#!/usr/bin/env bash

# VM config: 1cpu+512MB+256GB (will override first two with vagrant)
# General->Advanced: bidirectional + bidirectional
# System->Processor: PAE
# Display->Video: 24MB (retina) + disable 3D due to virtualbox bug
# Storage: add xubuntu CD + harddisk type SSD
# Network->Adapter 1->NAT + virtio-net

VBM='VBoxManage'
ISO="$1"
CPUS=1                          #small base
MEM=768                         #small base (512 is too small for desktop)
VRAM=24                         #prepare for retina
DISKSIZEGB=${2:-256}            #256GB by default

if [ ! -f "$1" ]; then

    echo 'Usage:'
    echo '$./0.sh iso-path [disk-size-in-GB]'

else

    # register VM
    read -ep 'VM name (try "XU64Base"): ' \
         $([ $BASH_VERSINFO -ge 4 ] && echo "-i XU64Base") \
         VMNAME
    VMUUID=$($VBM createvm --name $VMNAME --ostype Ubuntu_64 --register |
                    gawk '/^UUID:/{print $2}')
    echo "VM registered."

    # configure VM
    $VBM modifyvm $VMUUID \
         --memory $MEM \
         --vram $VRAM \
         --pae on \
         --cpus $CPUS \
         --rtcuseutc on \
         --accelerate3d off `#must disable due to virtualbox bug` \
         --accelerate2dvideo off \
         --nic1 nat \
         --nictype1 virtio \
         --mouse usbtablet \
         --audio coreaudio \
         --audiocontroller ac97 \
         --clipboard bidirectional \
         --draganddrop bidirectional \
         --usb on \
         --usbehci on

    # configure IDE and attach Xubuntu iso
    $VBM storagectl $VMUUID \
         --name IDE \
         --add ide \
         --controller PIIX4 \
         --portcount 2 \
         --hostiocache on \
         --bootable on
    $VBM storageattach $VMUUID \
         --storagectl IDE \
         --port 1 \
         --device 0 \
         --type dvddrive \
         --medium $ISO

    # attach Guest Additions iso
    # https://www.virtualbox.org/ticket/13040
    $VBM storageattach $VMUUID \
         --storagectl IDE \
         --port 1 \
         --device 1 \
         --type dvddrive \
         --medium emptydrive
    $VBM storageattach $VMUUID \
         --storagectl IDE \
         --port 1 \
         --device 1 \
         --type dvddrive \
         --medium additions

    # configure SATA and attach new hdd
    VMPREFIX=$($VBM showvminfo $VMUUID --machinereadable |
                      gawk -F = '/^CfgFile=/{print $2}' |
                      xargs dirname)
    DISKNAME="${VMPREFIX}/${VMNAME}.vdi"
    $VBM createhd --filename "${DISKNAME}" \
         --sizebyte $(($DISKSIZEGB * 1024 * 1024 * 1024)) \
         --format VDI > /dev/null
    $VBM storagectl $VMUUID \
         --name SATA \
         --add sata \
         --controller IntelAHCI \
         --portcount 1 \
         --hostiocache off \
         --bootable on
    $VBM storageattach $VMUUID \
         --storagectl SATA \
         --port 0 \
         --device 0 \
         --type hdd \
         --medium "$DISKNAME" \
         --nonrotational on
    echo "Disk image created."

    # instructions to continue
    cat <<"EOM"
VM created.

When running the Xubuntu installer:
1. NO need to 'Download updates while installing' (we will dist-upgrade later).
2. Enable installing 3rd-party software if you want a nice desktop environment.
3. Use LVM, always.
4. name          = vagrant
   computer name = XU64    (no base!)
   user          = vagrant (don't worry, we will create your account later)
   password      = vagrant
5. At 'Installation Complete', click 'Restart Now'.
6. A minute later you will see gibberish. Use VirtualBox to shutdown the VM.
7. Take a snapshot of the VM.

Enjoy!
EOM

fi
