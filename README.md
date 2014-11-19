# XU64Base Scripts

I wrote these scripts to help *me* set up [Xubuntu](http://xubuntu.org/) virtual
machines (VMs). I prefer [VirtualBox](https://www.virtualbox.org/), and I am
sharing these in the hope that it may save others some time.

My goal is to create a VM that can be used as a base Vagrant box. Out of my own
needs, the box should support:

* [Atom](https://atom.io/), for editing [Github-flavored Markdown](https://help.github.com/articles/github-flavored-markdown/)
* [Docker](https://www.docker.com/)
* [Google Chrome](http://www.google.com/chrome/)
* [IDA Pro](https://www.hex-rays.com/products/ida/)
* [OCaml](https://ocaml.org/) with [OPAM](http://opam.ocamlpro.com/), for developing with the CMU [Binary Analysis Platform (BAP)](https://github.com/BinaryAnalysisPlatform/)
* [Qira](https://github.com/BinaryAnalysisPlatform/qira)

## Step -1: Preparation

I cache a copy of the current Xubuntu LTS ISO in `~/ISOs` on all my machines.
These scripts are tested against this ISO, though I believe these scripts should
also work with other Ubuntu distributions as long as they are the same release.

## Step 0: Create VM in VirtualBox

The script `0.sh` creates and registers an empty VM with VirtualBox. Its
defaults are chosen to be sane for being a base Vagrant box.

```
yourself@host$ ./0.sh ~/ISOs/xubuntu-14.04.1-desktop-amd64.iso [disk-size-in-GB]
```

After running this script, start your VM to install Xubuntu. You should follow
the instructions printed by the script when interacting with the installer.

At this end of this step, you should have a VM with a fresh installation of
Xubuntu, i.e., it has __*never*__ been booted. Remember to take a snapshot as
instructed by the script!

## Step 1: First Boot

Boot the VM and login as `vagrant` with the password `vagrant`. Then run the
script `1.sh`.

```
vagrant@VM$ ./1.sh
```

The script starts with a *manual* portion, which will:
1. create a user for you, and
2. install VirtualBox Guest Additions.

After you have pressed Enter to close the Guest Additions installer, the script
will enter its *automatic* portion. You can sit back and relax for a minute.

When the script finishes, it will inform you to shutdown the VM and take a
snapshot.

## Step 2: Second Boot

Boot the VM and login as yourself. Then run the script `2.sh`.

```
yourself@VM$ ./2.sh
```

The script is entirely automatic. Its running time depends on your network
connection and the size of your disk image. 10 minutes would be a good guess.

__IMPORTANT:__ While you are waiting for the script to finish, edit
`versioning.json`. Make sure you edit the `name`, `description`, and `version`
settings. The `version` setting is a date string separated by dot used for
vagrant box versioning.

When the script finishes, it will show you how to create a base box using the
snapshot you have just created.

## Step 3: __*(to be continued)*__
