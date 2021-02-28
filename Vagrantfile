# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
  'controller'        => [1, 11]
}

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.manage_guest = true
  else
    raise "[-] ERROR: Please add vagrant-hostmanager plugin:  vagrant plugin install vagrant-hostmanager"
  end

  config.vm.box = "peru/ubuntu-20.04-server-amd64"
  # config.vm.synced_folder "./vagrant", "/vagrant"

  nodes.each do |prefix, (count, ip_start)|
    count.times do |i|
      if prefix == "controller"
        hostname = "%s" % [prefix, (i+1)]
      end

      config.ssh.insert_key = false

      config.vm.define "#{hostname}" do |box|
        box.vm.hostname = "#{hostname}"
        box.vm.network :private_network, ip: "10.0.0.#{ip_start+i}", :netmask => "255.255.255.0"
        box.vm.network :private_network, ip: "203.0.113.#{ip_start+i}", :netmask => "255.255.255.0"

        box.vm.provision :shell, :path => "vagrant/shell.sh"

        if hostname == "controller"
          box.vm.provision "shell", privileged: true, inline: <<-SHELL
            cd /home/vagrant/openstack/scripts/ubuntu
            ./apt_init.sh
            ./apt_upgrade.sh
            ./apt_pre-download.sh
            ./apt_install_mysql.sh
            ./install_rabbitmq.sh
            ./install_memcached.sh
            ./setup_keystone.sh
            ../test/get_auth_token.sh
            ./setup_placement_controller.sh
            ./setup_nova_controller.sh
            # ./setup_neutron_controller.sh
            # ./setup_neutron_controller_part_2.sh
          SHELL
        end

        # -rwxr-xr-x 1 root root 3090 Feb 27 23:03 create_xxx_node_pxeboot.sh
        # -rwxr-xr-x 1 root root  843 Feb 27 23:03 install_memcached.sh
        # drwxr-xr-x 2 root root 4096 Feb 27 23:03 mistral
        # -rwxr-xr-x 1 root root 5867 Feb 27 23:03 setup_cinder_controller.sh
        # -rwxr-xr-x 1 root root 8074 Feb 27 23:03 setup_cinder_volumes.sh
        # -rwxr-xr-x 1 root root 4307 Feb 27 23:03 setup_glance.sh
        # -rwxr-xr-x 1 root root 6132 Feb 27 23:03 setup_heat_controller.sh
        # -rwxr-xr-x 1 root root 4939 Feb 27 23:03 setup_horizon.sh
        # -rwxr-xr-x 1 root root 3327 Feb 27 23:03 setup_neutron_controller_part_2.sh
        # -rwxr-xr-x 1 root root 1742 Feb 27 23:03 setup_neutron_controller.sh
        # -rwxr-xr-x 1 root root 6316 Feb 27 23:03 setup_self-service_controller.sh
        # drwxr-xr-x 2 root root 4096 Feb 27 23:03 tacker
        
        box.vm.provider :virtualbox do |vbox|
          vbox.name = "#{hostname}"
          vbox.linked_clone = true if Vagrant::VERSION =~ /^1.8/

          if prefix == "controller"
            vbox.customize ["modifyvm", :id, "--memory", 4096]
            vbox.customize ["modifyvm", :id, "--cpus", 2]
          end

          vbox.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
          vbox.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
          vbox.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
        end
      end
    end
  end
end