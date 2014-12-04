# Bring Up Base Services

## Bring up the first etcd master

To bring up an etcd, we need to generate a peering certificate for it:

```console
admin$ cd $ETCD_PEER_CA
admin$ etcd-ca new-cert --ip $CORE01 core01
admin$ etcd-ca sign core01
admin$ etcd-ca export --insecure core01 >$CLUSTER_DIR/core01.tar
admin$ tar --append -f $CLUSTER_DIR/core01.tar peering.ca
admin$ scp $CLUSTER_DIR/core01.tar core@$CORE01:
admin$ rm $CLUSTER_DIR/core01.tar
```

Next, we'll set up these files in /etc/etcd, along with a peers file.

```console
core01$ tar xvf core01.tar
core01$ rm core01.tar
core01$ sudo mkdir /etc/etcd
core01$ sudo mv core01.crt /etc/etcd/peering.crt
core01$ sudo mv core01.key.insecure /etc/etcd/peering.key
core01$ sudo mv peering.ca /etc/etcd
core01$ sudo touch /etc/etcd/peers
core01$ sudo chown -R etcd:etcd /etc/etcd
core01$ sudo chmod -R u=rwX,go= /etc/etcd
```

Now, we need a bit more stuff in cloud-init, to start etcd and
configure it with the files we just provided.

```console
admin$ gotmpl $K8SFS/files/cloud-init-base-services-1 \
    hostname core01 \
    ssh_key "$(cat $SSH_CA/user_ca.pub)" \
    ip_address $CORE01 \
    >$CLUSTER_DIR/cloud-init
admin$ scp $CLUSTER_DIR/cloud-init core@$CORE01:
admin$ rm $CLUSTER_DIR/cloud-init
```

Finally, install and run the cloud-init file.

```console
core01$ sudo mv cloud-init /var/lib/coreos-install/user_data
core01$ sudo coreos-cloudinit --from-file=/var/lib/coreos-install/user_data
```

Etcd should now be running as a single-node data store. You can check
this by looking up the cluster's leader, which should be the address
of core01:

```console
admin$ curl http://$CORE01:4001/v2/leader
```

## Bring up Flannel

Flannel provides a virtual network substrate across hosts, and
interfaces with Kubernetes to provide the network plumbing it
requires. Turning it on is a simple matter of committing its
configuration to etcd and modifying cloud-init to start the
daemon. First, let's set the configuration in etcd:

```console
core01$ etcdctl set /coreos.com/network/config '{"Network": "10.0.0.0/8"}'
```

To enable flannel, just add the following to
`/var/lib/coreos-install/user_data` in the units section:

```yaml
- name: flanneld.service
  command: start
```

Note: this currently only works out of the box with the alpha build of
CoreOS. I'm strategizing on it becoming the stable release soon enough
that I won't care.

Because flannel fairly drastically changes the network and daemon
configuration, applying the cloud-init file again at runtime is not
good, you'll need to reboot the machine.

```console
core01$ sudo reboot
```

## Bring up fleet

The final brick before starting Kubernetes is Fleet. Fleet is another
cluster scheduling system that's somewhat less elaborate than
Kubernetes. We're going to use it in two ways: first, Kubernetes uses
fleet's metadata system to get information on machines in the
cluster. Second, we'll use Fleet to schedule the components of Ceph
and Kubernetes on the cluster. That way, most of our cluster job
management will be automatic even at the layers below Kubernetes.

Starting fleet is trivial: enable it in
`/var/lib/coreos-install/user_data`, just like flannel.

```yaml
- name: fleet.service
  command: start
```

This will start fleet when the machine reboots. To start it this first
time, we'll just launch it manually:

```console
core01$ sudo systemctl start fleet
```

Fleet should now be running. You can verify this with the `fleetctl` tool:

```console
core01$ fleetctl list-machines
```

This should list a single machine, core01.
