# Bootstrap Ceph

## Generate the monitor keyring

The monitor key is shared between all Ceph monitors, and allows them
to act as a distributed Kerberos KDC to manage client authentication.

```console
admin$ ceph-authtool --create-keyring $CEPH_CA/mon.keyring --gen-key -n mon. \
    --cap mon 'allow *'
```

In addition, we want our administration key to be accepted by Ceph
monitors, so that we can control the cluster. To this end, we import
the admin key into the monitor keyring:

```console
admin$ ceph-authtool $CEPH_CA/mon.keyring --import-keyring $CEPH_CA/admin.key
```

## Create the monitor datastore

```console
admin$ monmaptool --create --add a $CORE01 --fsid $(uuidgen) $CLUSTER_DIR/monmap
admin$ scp $CEPH_CA/mon.keyring $CLUSTER_DIR/monmap core@$CORE01:
admin$ rm $CEPH_CA/mon.keyring $CLUSTER_DIR/monmap
```

```console
core01$ sudo mkdir -p /var/lib/ceph/mon/ceph-a
core01$ sudo mv -f mon.keyring monmap /var/lib/ceph
core01$ sudo docker run -v /var/lib/ceph:/var/lib/ceph ulexus/ceph-base \
    /usr/bin/ceph-mon --mkfs -i a \
    --monmap /var/lib/ceph/monmap \
    --keyring /var/lib/ceph/mon.keyring
core01$ sudo rm /var/lib/ceph/mon.keyring /var/lib/ceph/monmap
```

## Start the first Ceph monitor

The systemd service configurations for Ceph binaries are preinstalled
by our cloud-init configuration, we just need to enable the
appropriate instance:

```console
core01$ sudo systemctl enable ceph-mon@a.service
core01$ sudo systemctl start ceph-mon@a.service
```
