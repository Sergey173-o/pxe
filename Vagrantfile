# Поднимает сервер PXE в VirtualBox и передаёт его Ansible.
Vagrant.configure("2") do |config|
  config.vm.define "pxeserver" do |server|
    server.vm.box = "bento/ubuntu-22.04"
    server.vm.hostname = "pxeserver"
    server.vm.synced_folder ".", "/vagrant", disabled: true
    server.vm.network "private_network", ip: "10.0.0.20", virtualbox__intnet: "pxenet"
    server.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

    server.vm.provider "virtualbox" do |vb|
      vb.memory = 1536
      vb.cpus = 2
    end

    server.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/provision.yml"
    end
  end
end

# v1 — 2026-11-07
# Добавлен PXE-сервер и автоматический запуск Ansible.
