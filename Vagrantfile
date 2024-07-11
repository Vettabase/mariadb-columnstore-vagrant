# -*- mode: ruby -*-
# vi: set ft=ruby :

if ENV['MDB_CLUSTER_SIZE']
  if ENV['MDB_CLUSTER_SIZE'] == 'SINGLE'
    cluster_size = 1
  else
    cluster_size = ENV['MDB_CLUSTER_SIZE'].to_i
  end
else
  cluster_size = 1
end

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

first_ip = 10
ip = '192.168.50'
primary_ip = "#{ip}.#{first_ip+1}"
msg = (
"<------------------------------->\n" +
"<   MariaDB ColumnStore Image   >\n" +
"<     by Vettabasse             >\n" +
"<------------------------------->\n" +
"\n" +
"MariaDB ColumnStore Unofficial Documentation Project:\n" +
"http://columnstore-docs.vettabase.com\n" +
"\n" +
"To obtain assistance or training from Vettabase:\n" +
"https://vettabase.com\n")

Vagrant.configure("2") do |config|
  config.vm.box = ENV['BOX'] || "generic/ubuntu2204"
  config.vm.synced_folder "sync", "/vagrant", type: "nfs",
    nfs_udp: false, nfs_version: 4

  1.upto(cluster_size) do |i|
    system('mkdir', '-p', "columnstore/data#{i}")
    config.vm.synced_folder "columnstore/data#{i}", "/var/lib/columnstore/data#{i}", type: "nfs",
      nfs_udp: false, nfs_version: 4, mount_options: ["rw", "sync"]
  end

  1.upto(cluster_size) do |i|
      vm_id = "cs#{i}"
      config.vm.define vm_id do |node|
        node.vm.post_up_message = msg

        node.vm.network "private_network", ip: "#{ip}.#{first_ip+i}"
        node.vm.hostname = vm_id
        node.vm.provision "shell", privileged: true, path: "install.sh", args: "#{i}",
            env: {
                'OS_CODENAME' => ENV['OS_CODENAME'] || 'jammy',
                'OS_SWAPPINESS' => ENV['OS_SWAPPINESS'] || 1,
                'OS_INSTALL_MYCLI' => ENV['OS_INSTALL_MYCLI'] || 0,
                'MDB_EXTRA_ENGINES' => ENV['MDB_EXTRA_ENGINES'] || 'CONNECT,SPIDER,BLACKHOLE',
                'MDB_VERSION' => ENV['MDB_VERSION'] || '11.3',
                'MDB_ALLOW_REMOTE_CONNECTIONS' => ENV['MDB_ALLOW_REMOTE_CONNECTIONS'] || 1,
                'MDB_CLUSTER_SIZE' => ENV['MDB_CLUSTER_SIZE'] || cluster_size,
                'MDB_MASTER_HOST' => ENV['MDB_MASTER_HOST'] || primary_ip
            }
    end
  end

end
