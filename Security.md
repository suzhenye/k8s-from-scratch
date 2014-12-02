# Security Roots Of Trust

While you can bring up a Kubernetes cluster with no authentication for
development purposes, we're going to do things right, and bring up a
cluster that properly authenticates all inter-machine communication.

All security in our cluster is going to be certificate-based, so we're
going to create a number of certificate authorities to manage those
trust hierarchies.

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
admin$ export SSH_CA=$CLUSTER_DIR/ca/ssh
admin$ mkdir -p $SSH_CA
admin$ ssh-keygen -f $SSH_CA/machine_ca -C machine-ca
admin$ ssh-keygen -f $SSH_CA/user_ca -C user-ca
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
admin$ ssh-keygen -f ~/.ssh/cluster_admin
admin$ ssh-keygen -s $SSH_CA/user_ca \
         -n core -I "Your Name <your.email@example.com>" \
         ~/.ssh/cluster_admin.pub
```

You should now have a file `~/.ssh/cluster_admin-cert.pub` in addition
to your public and private keys. This certificate will allow you to
log in as user `core`, on any machine that recognizes your user CA,
for ever.

Finally, add the machine CA to your known_hosts:

```console
admin$ echo "@cert-authority * $(cat $SSH_CA/machine_ca.pub)" >>~/.ssh/known_hosts
```

And with that, SSH root of trust setup is done.
