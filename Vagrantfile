# -*- mode: ruby -*-
# vi: set ft=ruby :

## To enable debugging, uncomment this line:
# ENV['VEEWEE_LOG'] = "debug"

provider = "virtualbox"

Vagrant.require_plugin "vagrant-smartos"

# Prepare the "smartos" box using veewee
definition_name = "smartos"
unless File.exist?("#{definition_name}.box")
  require 'veewee'
  puts "smartos.box not found. creating"
  ve = Veewee::Environment.new({ :definition_dir =>  "definitions" })
  box = ve.providers[provider].get_box(definition_name)
  box.build({'auto' => true,'force' => true, 'nogui' => true, 'disk_count' => 2})
  puts "exporting smartos.box"
  box.export_vagrant(definition_name)
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  # config.vm.box = definition_name

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "http://domain.com/path/to/above.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:

  # config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
  #   vb.customize ["modifyvm", :id, "--memory", "4096"]
  # end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file base.pp in the manifests_path directory.
  #
  # An example Puppet manifest to provision the message of the day:
  #
  # # group { "puppet":
  # #   ensure => "present",
  # # }
  # #
  # # File { owner => 0, group => 0, mode => 0644 }
  # #
  # # file { '/etc/motd':
  # #   content => "Welcome to your Vagrant-built virtual machine!
  # #               Managed by Puppet.\n"
  # # }
  #
  # config.vm.provision :puppet do |puppet|
  #   puppet.manifests_path = "manifests"
  #   puppet.manifest_file  = "site.pp"
  # end

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  # config.vm.provision :chef_solo do |chef|
  #   chef.cookbooks_path = "../my-recipes/cookbooks"
  #   chef.roles_path = "../my-recipes/roles"
  #   chef.data_bags_path = "../my-recipes/data_bags"
  #   chef.add_recipe "mysql"
  #   chef.add_role "web"
  #
  #   # You may also specify custom JSON attributes:
  #   chef.json = { :mysql_password => "foo" }
  # end

  # Enable provisioning with chef server, specifying the chef server URL,
  # and the path to the validation key (relative to this Vagrantfile).
  #
  # The Opscode Platform uses HTTPS. Substitute your organization for
  # ORGNAME in the URL and validation key.
  #
  # If you have your own Chef Server, use the appropriate URL, which may be
  # HTTP instead of HTTPS depending on your configuration. Also change the
  # validation key to validation.pem.
  #
  # config.vm.provision :chef_client do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
  #
  # If you're using the Opscode platform, your validator client is
  # ORGNAME-validator, replacing ORGNAME with your organization name.
  #
  # If you have your own Chef Server, the default validation client name is
  # chef-validator, unless you changed the configuration.
  #
  #   chef.validation_client_name = "ORGNAME-validator"

  global_zone = "smartos-hypervisor"

  # For the time being, use our dummy box
  # config.vm.box = definition_name
  config.ssh.username = "root"

  config.vm.provider :smartos do |smartos, override|
    # Required: This is which hypervisor to provision the VM on.
    # The format must be "<username>@<ip or hostname>"
    smartos.hypervisor = "root@#{global_zone}"

    # Required: This is the UUID of the SmartOS image to use for the VMs.
    # It must already be imported using `imgadm` before running `vagrant up`.
    # smartos.image_uuid = "ff86eb8a-a069-11e3-ae0e-4f3c8983a91c" # this is base64:13.4.0

    # Optional: The RAM allocation for the machine, defaults to the SmartOS default (256MB)
    smartos.ram = 1024

    # Optional: Disk quota for the machine, defaults to the SmartOS default (5G)
    # smartos.quota = 10

    # Optional: Specify the nic_tag to use
    # If omitted, 'admin' will be the default
    # smartos.nic_tag = "admin"

    # Optional: Specify a static IP address for the VM
    # If omitted, 'dhcp' will be used
    # smartos.ip_address = "1.2.3.4"

    # Optional: Specify the net-mask (required if not using dhcp)
    # smartos.subnet_mask = "255.255.255.0"

    # Optional: Specify the gateway (required if not using dhcp)
    # smartos.gateway = "255.255.255.0"

    # Optional: Specify a VLAN tag for this VM
    # smartos.vlan = 1234
  end

  # RSync'ed shared folders should work as normal
  config.vm.synced_folder "./", "/work-dir"

  config.vm.define global_zone do |box|
    box.vm.box = "#{definition_name}.box"
    box.vm.provider provider do |vm|
      # This is very virtualbox specific:
      vm.customize ["modifyvm", :id, "--memory", "4096"]
    end
  end

  config.vm.define "smartos-vagrant" do |box|
    box.vm.box = "smartos-dummy"
    box.vm.box_url = "https://github.com/joshado/vagrant-smartos/raw/master/example_box/smartos.box"
    box.vm.provider :smartos do |smartos, override|
      smartos.image_uuid = "ff86eb8a-a069-11e3-ae0e-4f3c8983a91c" # this is base64:13.4.0
    end
  end

end
