# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'find'

Vagrant.configure('2') do |config|

  config.vm.box = 'maverickwoo/xubuntu64-trusty'

  config.vm.provider 'virtualbox' do |vb|
    vb.gui = true
    vb.cpus = 4
    vb.memory = 6 * 1024
    vb.customize [
      'setextradata',
      :id,
      'VBoxInternal2/SharedFoldersEnableSymlinksCreate/vmshare',
      '1'
    ]
  end

  {'/Users/maverick/vmshare' => '/media/vmshare'}.each { |h, g|
    config.vm.synced_folder h, g
  }

  ['provision/public/root', 'provision/private/root'].each { |r|
    f = File.expand_path(File.dirname(__FILE__)) + '/' + r
    Dir.chdir(f) do
      Find.find('.') do |p|
        if !File.directory?(p)

          # TODO: ensure dirname(p) exists inside guest
          config.vm.provision 'file', run: 'always',
                              source: f + '/' + p,
                              destination: '/' + p

        end
      end
    end
  }

end
