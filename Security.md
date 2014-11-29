# Security Roots Of Trust

While you can bring up a Kubernetes cluster with no authentication for
development purposes, we're going to do things right, and bring up a
cluster that properly authenticates all inter-machine communication.

All security in our cluster is going to be certificate-based, so we're
going to create a number of certificate authorities to manage those
trust hierarchies.

We'll put all our roots of trust in our cluster directory:

```console
$ cd ~/mycluster
$ mkdir ca
```

## SSH CA

A little known feature of SSH is that is supports certificate
authorities, in addition to unattached keypairs. This is nice because
it lets us replace the usual authorized_key management with a single
entry allowing anyone holding a valid cert to log in.

Likewise, it frees us from having to verify host keys and deal with
host key checking failures, by issuing machines host certificates and
checking those against the CA on the client side.

Finally, although we won't use it here, another benefit of SSH certs over simple keys is that the certs can be given an expiry date, which simplifies access management and rotation.

We'll have two separate CAs, one for machines and one for users. This
is so that machine certificates cannot be used to log into other
machines, and user certificates cannot be used to impersonate
machines.

```console
$ cd ~/mycluster/ca
$ mkdir ssh
$ cd ssh
$ ssh-keygen -f machine_ca
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in machine_ca.
Your public key has been saved in machine_ca.pub.
The key fingerprint is:
9a:d1:a2:31:05:3d:1c:7c:c6:73:09:a5:88:c7:ec:dd dave@alya
$ ssh-keygen -f user_ca
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in user_ca.
Your public key has been saved in user_ca.pub.
The key fingerprint is:
ae:f9:a3:b1:bb:0b:8f:a7:81:e1:f2:b9:f2:f5:15:b3 dave@alya
```

It is _strongly recommended_ to set good passphrases for both of these
keys when prompted. Remember, they are the root of trust for your
cluster, so if someone can get their hands on the key and figure out
the passphrase, they get access to everything.

Depending on your local ssh's preferences, you may end up a different
key type and length. That's fine.

### Configuring your ssh client

Now that we have our SSH roots of trust, let's take this opportunity
to set ourselves up with a user certificate, and to tell ssh about our
machine CA.

First, let's create ourselves a user certificate:

```console
$ ssh-keygen -f ~/.ssh/mycluster
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in ~/.ssh/mycluster.
Your public key has been saved in ~/.ssh/mycluster.pub.
The key fingerprint is:
c2:89:0b:2b:df:f6:2b:e9:9e:20:e7:bd:4d:5e:30:f4 dave@alya
$ ssh-keygen -s user_ca -n core -I "Your Name <your.email@example.com>" ~/.ssh/mycluster.pub
Signed user key ~/.ssh/mycluster.pub: id "Your Name <your.email@example.com>" serial 0 for core valid forever
```

You should now have a file `~/.ssh/mycluster-cert.pub` in addition to
your public and private keys. This certificate will allow you to log
in as user `core`, on any machine that recognizes your user CA, for
ever.

Finally, add the machine CA to your known_hosts:

```console
$ echo "@cert-authority * $(cat machine_ca.pub)" >>~/.ssh/known_hosts
```

And with that, SSH root of trust setup is done.
