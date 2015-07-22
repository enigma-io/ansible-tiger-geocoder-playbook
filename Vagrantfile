require 'json'
require 'fileutils'
# read service definitions
service = File.read('./tiger-local-vm.json')
svc = JSON.parse(service)

Vagrant.configure("2") do |config|
  
  config.vm.box = "trusty64"
  config.vm.box_url = "https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box"

  config.vm.define "tiger" do |machine|
    machine.vm.provider :virtualbox do |v|  
      if svc["ram"]
        v.memory = svc["ram"]
      else
        v.memory = 8096
      end
      if svc["cpu"]
        v.cpus = svc["cpu"]
      else
        v.cpus = 4
      end
      # include a mounted drive
      if svc["tiger_vb_mount"]
        d = svc["tiger_vb_mount"]
        v.customize [
          "createhd", 
          "--filename", d["path"], 
          "--size", d["size"]
        ]
        v.customize [
          "storageattach", :id, 
          "--storagectl", d["storagectl"],
          "--port", d["port"], 
          "--device", d["device"], 
          "--type", d["type"], 
          "--medium", d["path"]
        ]
      end
    end

    machine.vm.provision "ansible" do |ansible|
      ansible.extra_vars = { ansible_ssh_user: "vagrant", hostname: "tiger"}
      ansible.playbook = "./provisioning/tigergeocoder.yml"
      ansible.verbose = "vvvv"
      ansible.extra_vars = {
        tiger_local_vm: true,
        tiger_mounted_drive_path: "/dev/sdb"
      }
    end
  end
end