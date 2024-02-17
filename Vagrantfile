# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = ENV['BOX'] || "generic/ubuntu2204"
  config.vm.synced_folder ".", "/vagrant"

  1.upto(1) do |i|
      config.vm.define "cs#{i}" do |node|
        node.vm.network "private_network", ip:"192.168.50.1#{i}"
        node.vm.provision "shell", privileged: true, path: "install.sh",
            env: {
                'OS_SWAPPINESS' => ENV['OS_SWAPPINESS'] || 1,
                'OS_INSTALL_MYCLI' => ENV['OS_INSTALL_MYCLI'] || 1
            }
    end
  end

end
