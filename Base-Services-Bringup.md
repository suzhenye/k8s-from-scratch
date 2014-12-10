# Bring Up Base Services

## Etcd

If we need another etcd master, we need to give it some keys. The
systemd configuration will automatically start etcd once the keys are
installed

### Create etcd certificates

If the machine you're setting up is going to be an etcd server for the
cluster, you need to generate some certificates for it:

```console
admin$ etcd-ca --depot-path=$ETCD_PEER_CA new-cert --passphrase "" --ip $INSTALLER_IP core01
admin$ etcd-ca --depot-path=$ETCD_PEER_CA sign core01
admin$ etcd-ca --depot-path=$ETCD_CLIENT_CA new-cert --passphrase "" --ip $INSTALLER_IP core01
admin$ etcd-ca --depot-path=$ETCD_CLIENT_CA sign core01
```

### Install etcd certificates

```console
admin$ etcd-ca --depot-path=$ETCD_PEER_CA export --passphrase "" --insecure core01 | \
  ssh root@$CORE01 tar xv -C /etc/etcd \
    --xform=s/core01/peer/ --xform=s/.insecure// \
    --show-transformed-names
admin$ etcd-ca --depot-path=$ETCD_CLIENT_CA export --passphrase "" --insecure core01 | \
  ssh root@$CORE01 tar xv -C /etc/etcd \
    --xform=s/core01/client/ --xform=s/.insecure// \
    --show-transformed-names
```

### Start etcd

Now that it has peering keys, the etcd master will start automatically
on the next boot. Until then, we can start it manually.

```console
core01$ sudo systemctl start etcd
```

TODO: adjust instructions for when _adding_ a peer to an existing
cluster.

### Verify that it's working

We can check that etcd is working by querying the current cluster
leader.

```console
core01$ curl https://127.0.0.1:4001/v2/leader
```

## Fleet

Fleet should have auto-started, registered itself in etcd, and become
the fleet master for the cluster (since it's the only instance). We
can verify this with `fleetctl`

```console
core01$ fleetctl list-machines
```

This should show a single machine in the cluster, core01.

## Flannel

Flannel, on the other hand, is started, but is crash-looping. It reads
most of its configuration from etcd, and we haven't given it one, so
it's spinning waiting for us to write it. Let's do that now:

```console
core01$ etcdctl set /coreos.com/network/config '{"Network": "10.0.0.0/8"}'
```

Within a few seconds, flanneld should start correctly. You can check
this by looking for a `flannel0` network interface in `sudo ip link`.
