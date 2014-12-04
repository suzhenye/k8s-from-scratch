# Bring Up Base Services

The cloud-init configuration we gave during installation took care of
most of it: etcd is running if we wanted it to (TODO: set up an etcd
proxy on localhost:4001 for non-participating machines, for
transparent configuration), and we can verify this with `etcdctl`, and
by asking who the elected etcd leader is:

```console
core01$ etcdctl ls
core01$ curl https://127.0.0.1:4001/v2/leader
```

That should print nothing, though behind the scenes it's connected to
etcd over HTTPS and found that there's nothing in etcd yet.

Similarly, fleet should have auto-started, registered itself in etcd,
and become the fleet master for the cluster (since it's the only
instance). We can verify this with `fleetctl`

```console
core01$ fleetctl list-machines
```

This should show a single machine in the cluster, core01.

Flannel, on the other hand, is started, but is crash-looping. It reads
most of its configuration from etcd, and we haven't given it one, so
it's spinning waiting for us to write it. Let's do that now:

```console
core01$ etcdctl set /coreos.com/network/config '{"Network": "10.0.0.0/8"}'
```

Within a few seconds, flanneld should start correctly. You can check
this by looking for a `flannel0` network interface in `sudo ip link`.
