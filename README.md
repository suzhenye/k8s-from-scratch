# Kubernetes From Scratch

Kubernetes From Scratch, an LFS analog for standing up a robust
Kubernetes cluster on bare metal.

This is very much a WIP, and is currently a braindump of my own notes
as I work towards this goal.

# Rules of engagement

- No cloud services required to run the cluster. If we use L3/L7 load
  balancing, five nines datastores and so forth, we beg the question
  of bringing up a cluster by relying on another cluster that we don't
  own. Things like Docker Hub for packaging are acceptable, on the
  reasoning that the registry setup should be easy to replicate on our
  cluster once up.
- It's okay to script stuff, but we must dig into, and understand what
  the script does. No magic black boxes.
- Bringup should require a single server only. It's okay to sacrifice
  reliability (i.e. you can't have data replicas) during the initial
  bringup.
- Once bringup is complete, scaling out should require a minimum of
  effort - at most 10 minutes of manual labor, automatable down to
  zero.
- In this version, we assume that an external actor is providing a
  network with internet access and DHCP services that can be
  configured with static leases. A $50 wifi router for
  instance. Future versions may expand the bringup to cover that
  actor.

# General structure

We start by bringing up a full cluster on a single machine:

1. [Collect prerequisites](/Prerequisites.md).
1. [Create security roots of trust](/Security.md).
1. [Bring up CoreOS on the bare metal](/CoreOS-Bringup.md).
1. [Bring up base services](/Base-Services-Bringup.md).
1. Bring up Ceph on fleet.
1. Bring up k8s master on fleet.
1. Bring up k8s minion on fleet.

At this point, we have a working single-machine k8s
cluster. Reliability is currently nil, due to the lack of replication,
but the foundation is in place for us to scale out.

From here, we can add a new machine with a simplified procedure:

1. [Bring up CoreOS on the bare metal](/CoreOS-Bringup.md).
1. Bring up base services: etcd, fleet, flannel.

At this point, fleet takes over and schedules Ceph and a k8s minion,
completing the bringup for us.

Note that, with appropriate PXE support, the procedure could be shortened to:

1. Power on new machine.
