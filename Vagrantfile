# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "base"
  
  # Forward port 8080 of Tomcat6 to 8085 in host machine
  config.vm.network :forwarded_port, guest: 8080, host: 8085
  
  # Forward port 9418 of GIT to 8086 in host machine
  config.vm.network :forwarded_port, guest: 9418, host: 8086
  
  # Sync folder repository to delivery in order to commit sources
  config.vm.synced_folder "./delivery", "/home/vagrant/delivery"
  
  # Update all current packages and install unzip package
  config.vm.provision "shell", path: "./scripts/apt-update.sh"
  
  # Enable provision puppet to install tomcat, git and init auto-commit, auto-deploy jobs
  config.vm.provision "puppet" do |puppet|
	puppet.module_path = "./scripts/puppet/modules"
	puppet.manifests_path = "./scripts/puppet/manifests"
    puppet.manifest_file = "default.pp"
	
  end
  
end
