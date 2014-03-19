# Much of this borrowed from: github.com/rarenerd/veewee-definitions
set -x
date > /usbkey/vagrant_box_build_time

CDROM=c0t0d0
BOOTDISK=c2t0d0
ZONESDISK=c2t1d0

export PATH=/opt/local/bin:/opt/local/sbin:/usr/bin:/usr/sbin

PrepareBootScript() {
  mkdir -p /opt/custom/bin

  cat <<BOOT > /opt/custom/bin/vagrant
#!/bin/bash

echo "Waiting on svc:/network/physical:default."
while ! svcs svc:/network/physical:default | grep ^online > /dev/null ;do
  echo -n "."
  sleep 1
done
echo ""

while ! svcs svc:/system/filesystem/smartdc:default | grep ^online > /dev/null ;do
  sleep 1
done

export PATH=/opt/local/bin:/opt/local/sbin:/usr/bin:/usr/sbin

pkgin -y update
pkgin -y install sudo gsasl
ln -sf /usr/lib/libsasl.so.1 /opt/local/lib/libsasl2.so.3

mkdir -p /root/.ssh

# curl -k https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > /root/.ssh/authorized_keys
cat <<EOH > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
EOH

mkdir /mnt-vboxguest
mount -r -F hsfs /dev/dsk/c1t0d0s2 /mnt-vboxguest
pkgtrans /mnt-vboxguest/VBoxSolarisAdditions.pkg /tmp all

# This borrowed from: github.com/groundwater/vagrant-smartos
REL=/tmp/SUNWvboxguest/reloc
mkdir -p /opt/vagrant/bin
cp \$REL/opt/VirtualBoxAdditions/amd64/vboxfs      /kernel/fs/amd64/
cp \$REL/opt/VirtualBoxAdditions/amd64/vboxfsmount /opt/vagrant/bin
cp \$REL/usr/kernel/drv/amd64/vboxguest            /kernel/drv/amd64/
cp \$REL/usr/kernel/drv/vboxguest.conf             /kernel/drv/

rm -fr /tmp/SUNWvboxguest
umount /mnt-vboxguest

# Enable kernel modules
add_drv -m '* 0666 root sys' -i 'pci80ee,cafe' vboxguest
devfsadm -i vboxguest
ln -fns /devices/pci@0,0/pci80ee,cafe@4:vboxguest /dev/vboxguest
modload /kernel/fs/amd64/vboxfs

# TODO: Find a way to make this a global default, or run periodically for zones.
# Copy vboxfs mount command to zones
for zone in /zones/* ; do
  CUSTOM_BIN=/zones/\$zone/root/opt/local/bin
  mkdir -p \$CUSTOM_BIN
  cp /opt/vagrant/bin/vboxfsmount \$CUSTOM_BIN
  zonecfg -z \$zone "set fs-allowed=vboxfs"
done
true
BOOT

  chmod 755 /opt/custom/bin/vagrant

  mkdir -p /opt/custom/smf

  cat <<VAGRANT_XML > /opt/custom/smf/vagrant.xml
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
 
<service_bundle type='manifest' name='vagrant'>
<service
        name='vagrant/setup'
        type='service'
        version='1'>
 
        <create_default_instance enabled='true' />
 
        <single_instance />
 
        <dependency
                name='fs-joyent'
                grouping='require_all'
                restart_on='none'
                type='service'>
                <service_fmri value='svc:/system/filesystem/smartdc' />
        </dependency>
 
        <exec_method
                type='method'
                name='start'
                exec='/opt/custom/bin/vagrant'
                timeout_seconds='0'>
        </exec_method>
 
        <exec_method
                type='method'
                name='stop'
                exec=':true'
                timeout_seconds='0'>
        </exec_method>
 
        <property_group name='startd' type='framework'>
                <propval name='duration' type='astring' value='transient' />
        </property_group>
 
        <stability value='Unstable' />
 
</service>
</service_bundle>
VAGRANT_XML

}

# Boot from local disk (thanks to Andrzej Szeszo (@aszeszo))
SetupBootDisk() {

  echo Mounting cdrom...
  mkdir /mnt-cdrom
  mount -F hsfs /dev/dsk/${CDROM}p0 /mnt-cdrom

  echo Setting up the boot disk...
  cat <<EOF | fdisk -F /dev/stdin /dev/rdsk/${BOOTDISK}p0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
EOF
  NUMSECT=$(iostat -En $BOOTDISK | awk '/^Size:/ { sub("<",""); \
    print $3/512 - 2048 }')
  fdisk -A 12:128:0:0:0:0:0:0:2048:$NUMSECT /dev/rdsk/${BOOTDISK}p0
  echo y|mkfs -F pcfs -o fat=32 /dev/rdsk/${BOOTDISK}p0:c

  echo Mounting boot disk...
  mkdir /mnt-boot
  mount -F pcfs /dev/dsk/${BOOTDISK}p1 /mnt-boot

  echo Copying SmartOS platform boot files to the boot disk...
  rsync -a /mnt-cdrom/ /mnt-boot/

  echo "Installing GRUB..."
  grub --batch <<EOF >/dev/null 2>&1
device (hd0) /dev/dsk/${BOOTDISK}p0
root (hd0,0)
install /boot/grub/stage1 (hd0) (hd0,0)/boot/grub/stage2 p (hd0,0)/boot/grub/menu.lst
quit
EOF

  echo "Fixing GRUB kernel & module menu.lst entries..."
  sed -i '' -e 's%kernel /platform/%kernel (hd0,0)/platform/%' \
    -e 's%module /platform/%module (hd0,0)/platform/%' \
    /mnt-boot/boot/grub/menu.lst

  echo "Setting GRUB timeout to 0s..."
  sed -i '' 's/timeout=.*/timeout=0/' /mnt-boot/boot/grub/menu.lst

  umount /mnt-cdrom
  umount /mnt-boot

  rmdir /mnt-cdrom
  rmdir /mnt-boot
}

SetupPackageManager() {
  curl -k http://pkgsrc.joyent.com/packages/SmartOS/bootstrap/bootstrap-2013Q3-`uname -p`.tar.gz | gzcat | /usr/bin/tar xf - -C /
  pkg_admin rebuild
  pkgin -y up
}

InstallOmnibusChef() {
  curl -k http://cuddletech.com/smartos/Chef-fatclient-SmartOS-10.14.2.tar.bz2 | bunzip2 | tar xf - -C /
}

InstallChef() {
  # Install build dependencies for Chef
  pkgin -y update
  pkgin -y install gcc47 gcc47-runtime scmgit-base gmake ruby193-base ruby193-yajl ruby193-nokogiri ruby193-readline pkg-config

  OLDPATH=${PATH}
  export PATH=/opt/local/gnu/bin:/opt/local/gcc47/bin:/opt/local/bin:/opt/local/sbin:/usr/bin:/usr/sbin
  
  gem193 update --system
  
  # Install Chef
  gem193 install --no-ri --no-rdoc ohai
  gem193 install --no-ri --no-rdoc chef
  gem193 install --no-ri --no-rdoc rb-readline

  export PATH=${OLDPATH}
}

# Do these once on
SetupBootDisk
SetupPackageManager
#InstallChef
#InstallOmnibusChef
PrepareBootScript

exit
