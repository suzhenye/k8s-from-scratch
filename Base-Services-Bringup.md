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
