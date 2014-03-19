# veewee-vagrant-smartos

# Dependencies

This project uses the gem installed vagrant directly from github:

```bash
bundle update
```

The vagrant-smartos plugin is used to create the guest vagrant zone:

```bash
bundle exec vagrant plugin install --plugin-prerelease --plugin-source https://rubygems.org/ vagrant-smartos
```

# Using

Yes, it is this deceptively simple:

```
bundle exec vagrant up
```

The first time this is run, it will create the smartos.box based on the veewee definitions.

Beyond this point, everything is vanilla vagrant.

Both the smartos hypervisor (global zone) and the vagrant zone are directly accessible as separate vagrant instances:

```
bundle exec vagrant ssh smartos-hypervisor
bundle exec vagrant ssh vagrant
```

## Cleanup

Cleaning up after vagrant requires destroying the vagrant instances:

```bash
bundle exec vagrant destroy -f
```

Cleaning up after veewee requires a few steps.

The first step is to remove the generated smartos.box

```bash
bundle exec vagrant box remove smartos.box
rm -f smartos.box
```

If veewee is running in debug mode, it leaves the smartos virtualbox around as well. If you've used VMWare, kvm, or something other than VirtualBox for your vagrant, this will be different for you:

```bash
VBoxManage controlvm smartos poweroff
VBoxManage unregistervm smartos --delete
```

Lastly, you will find an iso directory was added with the guest additions for your virtualization, as well as the latest smartos iso.

```bash
rm -fr iso
```

## Bibliography

Here are a few projects that were scrounged to make this possible:

https://github.com/joshado/vagrant-smartos
https://github.com/jedi4ever/veewee/blob/master/doc/customize.md
https://github.com/rarenerd/veewee-definitions/blob/master/smartos/definition.rb
https://github.com/groundwater/vagrant-smartos/blob/master/GLOBALZ/opt/custom/bin/vagrant-boot


