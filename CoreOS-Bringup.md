# Bring up CoreOS on bare metal

This is fairly well documented on the CoreOS website, but there are a
few points of discussion that are specific to bringing up CoreOS on
bare metal, versus cloud services.

The most important is that a CoreOS installation out of the box _does
not allow any access, remote or local_. As such, providing a
cloud-init configuration is not optional, even for bare metal.

In this stage, we'll use an absolutely minimal cloud-init that will
give us remote access after installation, and work on a more elaborate
configuration in the next step.

## Getting CoreOS and booting it

Download the latest stable CoreOS ISO image from
[their website](https://www.coreos.com), and burn it to a USB stick.

```console
admin$ dd if=coreos_production_iso_image.iso of=/dev/<your-usb-stick>
```

Plug the USB stick into the server and power it on. Depending on the
hardware, you may need to manually specify a boot from USB. Also note
that modern hardware with USB 3.0 ports tend to only boot from the
non-blue USB 2.0 ports. Try changing ports if the boot isn't catching.

Once the boot catches, CoreOS will start up in a ramdisk, grab a DHCP
lease, and drop you in a shell as the `core` user.

If you want manual control over the IP addressing scheme, now would be
a good time to find the machine's MAC address, and enter a static DHCP
lease for your desired IP address in the router.

```console
ramdisk$ sudo ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT qlen 1000
    link/ether 52:54:00:8b:0e:0f brd ff:ff:ff:ff:ff:ff
```

Either way, for now, let's remember the ramdisk's IP (substitute your
own):

```console
admin$ export INSTALLER_IP=192.168.42.10
```

## Enable temporary remote access

We're going to have to copy a cloud-init configuration to the server,
and unless you like typing ssh keys by hand, that means we need to set
up remote access. CoreOS always runs sshd, so it's just a matter of
setting a password so that we can connect:

```console
ramdisk$ sudo passwd core
Changing password for core
Enter the new password (minimum of 5 characters)
Please use a combination of upper and lower case letters and numbers.
New password: 
Re-enter new password: 
passwd: password changed.
```

The password need not be fancy, it won't persist past the installation
phase.

## Create and copy a basic cloud-init file.

We're going to start with the bare minimum cloud-init file:

```console
admin$ gotmpl $K8SFS/files/cloud-init-minimal \
    hostname core01 \
    ssh_key "$(cat $SSH_CA/user_ca.pub)" \
    >$CLUSTER_DIR/cloud-init
```

This'll produce the following cloud-init file:

```yaml
#cloud-config

hostname: core01
ssh_authorized_keys
- cert-authority ssh-rsa AAAAB...w== user-ca
```

Copy this file to the CoreOS ramdisk:

```console
admin$ scp $CLUSTER_DIR/cloud-init core@$INSTALLER_IP:
Password:
cloud-init 100% 500     5.3KB/s   00:00
admin$ rm $CLUSTER_DIR/cloud-init
```

## Install CoreOS

Finally, we're ready to install CoreOS to the server's hard drive. First, identify the appropriate block device for the CoreOS hard drive:

```console
ramdisk$ lsblk
NAME                        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda                           8:0    0 119.2G  0 disk  
```

On my machine, that's `/dev/sda`, but yours may be different. Install
CoreOS to that device, specifying our minimal cloud-init:

```console
ramdisk$ sudo coreos-install -d /dev/sda -c cloud-init
```

## Set up SSH host certs

Before we reboot into the fresh system, we need to sign the new
machine's host certificates, so that our authentication Just
Works. The problem is that, by default, the host keys are generated
during the first boot by a systemd unit, at which point we don't have
a good way of pushing host certs to the machine.

There are better ways to deal with this once we have PKI-integrated
PXE booting, but for now, we can just mount the filesystem and set up
SSH by hand. So, let's mount the necessaries on /mnt:

```console
ramdisk$ sudo mount -o subvol=root /dev/sda9 /mnt
ramdisk$ sudo mount -o bind /usr /mnt/usr
ramdisk$ sudo mount -o bind /dev /mnt/dev
```

/usr is necessary because the basic root filesystem doesn't have any
programs, and /dev is needed for both /dev/null and /dev/urandom. Now
though, we can generate the host SSH keys, and undo the bind mounts.

```console
ramdisk$ sudo chroot /mnt /usr/bin/ssh-keygen -A
ramdisk$ sudo umount /mnt/dev
ramdisk$ sudo umount /mnt/usr
```

Now, from the machine with the SSH CA keys, we grab the host public
keys, sign them, and push the certificates back:

```console
admin$ export SIGN_TMP=$(mktemp -d)
admin$ scp core@$INSTALLER_IP:'/mnt/etc/ssh/ssh_host_*.pub' $SIGN_TMP
admin$ for i in $SIGN_TMP/ssh_host_*.pub; do \
         ssh-keygen -s $SSH_CA/machine_ca -I core01 -h $i; \
       done
admin$ scp $SIGN_TMP/ssh_host_*-cert.pub core@$INSTALLER_IP:
admin$ rm -rf $SIGN_TMP
```

We can't copy the certs straight into the final directory, because
core@ isn't allowed to do that. However, we can sudo-move them now:

```console
ramdisk$ sudo mv ssh_host_*-cert.pub /mnt/etc/ssh
ramdisk$ sudo chown 0:0 /mnt/etc/ssh/ssh_host_*-cert.pub
ramdisk$ sudo chmod 0644 /mnt/etc/ssh/ssh_host_*-cert.pub
```

There's one final step to perform, which is to register these
certificates in the sshd configuration, so that it presents them to
users connecting. On CoreOS, the default sshd_config is a symlink to
the read-only vendor partition, so we need to make it mutable
first.

```console
ramdisk$ rm /mnt/etc/ssh/sshd_config
ramdisk$ cp /usr/share/ssh/sshd_config /mnt/etc/ssh/sshd_config
ramdisk$ for i in /mnt/etc/ssh/ssh_host_*-cert.pub; do \
           echo "HostCertificate /etc/ssh/$(basename $i)" >>/mnt/etc/ssh/sshd_config; \
         done
```

```
TODO: do this a bit more nicely in cloud-init, rather than by hand.
```

We're done now. Remove the USB stick, and reboot:

```console
ramdisk$ sudo reboot
```

If nothing went wrong, the server will boot to disk, and present you
with a nice CoreOS login prompt. At this point, you can only interact
with the machine remotely, so try that now:

```console
admin$ ssh core@$INSTALLER_IP
```

This should log you in with no host verification prompt and no
password.

And just for cleanliness, let's promote the environment variable we
were using:

```console
admin$ export CORE01=$INSTALLER_IP
admin$ unset INSTALLER_IP
```

If you changed the DHCP lease settings earlier, you may need to adjust
this to specify the new IP for the machine.

## Optional: set a backup root password

Unlike cloud VMs, we don't have an emergency backdoor into our system
courtesy of the cloud provider, so we should set our own up, in the
form of a root password.

Since this will be seldom used, you have two options: either make the
password very long and random (for instance, `pwgen -s 30`), or make
it short and memorable, but disable ssh-as-root. In that case, in an
emergency you'd need to be physically at the machine's console to get
access.

```console
core01$ sudo passwd
Changing password for root
Enter the new password (minimum of 5 characters)
Please use a combination of upper and lower case letters and numbers.
New password: 
Re-enter new password: 
passwd: password changed.
```

If you want to disable ssh-as-root, stay tuned, we'll do that in the
next chapter.

That's it! Basic CoreOS bringup is done. Next up is [bringing up base services](/Base-Services-Bringup.md).
