# Bring Up Base Services

Now that CoreOS is installed, we need to bring up the basic machine
services that Kubernetes requires. These are etcd, fleet and flannel.

The configuration here varies slightly depending on whether we're
setting up a k8s master, or a simple minion. The primary difference is
that we want to set up etcd as a peering master on a master machine,
and as a simple proxy on minions.

### Confession

Etcd proxy mode is a new feature in etcd 0.5.0, which at the time of
writing isn't released or integrated in CoreOS yet. However, it makes
secure and config-free setup so much easier that I'm going to write
this on the assumption that you're running 0.5.0.

In the meantime, you can hack up your CoreOS installation to run 0.5.0 ahead of time, by running the following on the CoreOS machine:

```console
$ sudo mkdir -p /opt
$ docker pull quay.io/coreos/etcd-git:latest
$ docker run --name etcd-git quay.io/coreos/etcd-git:latest /go/bin/etcd --version
$ docker cp etcd-git:/go/bin/etcd /opt/etcd
$ docker rm -v -f etcd-git
$ sudo mkdir -p /etc/systemd/system/etcd.service.d
$ sudo cat >/etc/systemd/system/etcd.service.d/git.conf <<EOF
[Service]
ExecStart=/opt/etcd
EOF
$ sudo systemctl restart etcd
```

To undo it later, when etcd 0.5.0 is in CoreOS:

```console
$ sudo rm -f /opt/etcd
$ sudo rm -f /etc/systemd/system/etcd.service.d/git.conf
$ sudo systemctl restart etcd
```
