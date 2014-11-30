# -*- mode: ruby -*-
# vi: set ft=ruby :

hostvmshare="/Users/maverick/vmshare"
guestvmshare="/media/vmshare"

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "maverickwoo/xubuntu64-trusty"
  config.vm.synced_folder hostvmshare, guestvmshare
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.cpus = 4
    vb.memory = 6 * 1024
  end
end
