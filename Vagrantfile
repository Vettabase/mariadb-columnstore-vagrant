# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = ENV['BOX'] || "generic/ubuntu2204"
  config.vm.synced_folder ".", "/vagrant"

  1.upto(1) do |i|
      vm_id = "cs#{i}"
      config.vm.define vm_id do |node|
        config.vm.post_up_message = (
            "<------------------------------->\n" +
            "<   MariaDB ColumnStore Image   >\n" +
            "<     by Vettabasse             >\n" +
            "<------------------------------->\n" +
            "\n" +
            "MariaDB ColumnStore Unofficial Documentation Project:\n" +
            "http://columnstore-docs.vettabase.com\n" +
            "\n" +
            "To obtain assistance or training from Vettabase:\n" +
            "https://vettabase.com\n"
        )

        node.vm.network "private_network", ip:"192.168.50.1#{i}"
        config.vm.hostname = vm_id
        node.vm.provision "shell", privileged: true, path: "install.sh",
            env: {
                'OS_CODENAME' => ENV['OS_CODENAME'] || 'jammy',
                'OS_SWAPPINESS' => ENV['OS_SWAPPINESS'] || 1,
                'OS_INSTALL_MYCLI' => ENV['OS_INSTALL_MYCLI'] || 1,
                'MDB_EXTRA_ENGINES' => ENV['MDB_EXTRA_ENGINES'] || 'CONNECT,SPIDER,BLACKHOLE',
                'MDB_VERSION' => ENV['MDB_VERSION'] || '11.3',
                'MDB_ALLOW_REMOTE_CONNECTIONS' => ENV['MDB_ALLOW_REMOTE_CONNECTIONS'] || 1
            }
    end
  end

end
