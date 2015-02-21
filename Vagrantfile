# -*- mode: ruby -*-
# vi: set ft=ruby :

def provision(config, from, to)
  require 'find'
  from.each { |dir|
    fulldir = File.expand_path(File.dirname(__FILE__)) + '/' + dir
    if File.directory?(fulldir)
      Dir.chdir(fulldir) do
        Find.find('.') do |p|
          if !File.directory?(p)

            config.vm.provision 'file', run: 'always',
                                source: fulldir + '/' + p,
                                destination: to + '/' + p

          end
        end
      end
    end
  }
end

Vagrant.configure('2') do |config|

  config.vm.box = 'maverickwoo/xubuntu64-trusty'

  config.vm.provider 'virtualbox' do |vb|
    vb.gui = true
    vb.cpus = 4
    vb.memory = (ENV['M'] || '6').to_i * 1024
    vb.customize [
      'setextradata',
      :id,
      'VBoxInternal2/SharedFoldersEnableSymlinksCreate/vmshare',
      '1'
    ]
  end

  {
    '/Users/maverick/vmshare' => '/media/sf_vmshare',
    '/Users/maverick/Programming/maverickwoo/qira-docker' => '/media/qira-docker'
  }.each { |h, g|
    config.vm.synced_folder h, g, mount_options: ['dmode=775,fmode=664']
  }

  provision config, ['provision/public/root', 'provision/private/root'], ''

end
