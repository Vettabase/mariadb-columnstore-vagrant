# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.synced_folder ".", "/vagrant"

  1.upto(1) do |i|
      config.vm.define "cs#{i}" do |node|
        node.vm.network "private_network", ip:"192.168.50.1#{i}"
    end
  end

end