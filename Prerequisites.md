# Collect Prerequisites

## Stylistic conventions

We're going to be talking about running commands on a number of
different machines, those machines being in a variety of states. To
make things easier to follow, the rest of these documents uses the
following conventions.

The administrator's control machine exists outside of the cluster, and
is called `admin`. Commands that are to be run on this machine will
look like this:

```console
admin$ echo "This is a command on the admin machine"
```

Machines in the cluster are named `core01` through `core99`. A command
run on a cluster machine looks like this:

```console
core04$ echo "Running on the 4th cluster machine"
```

Occasionally in early setup, we'll be running coreos in a
ramdisk. Those commands will look like:

```console
ramdisk$ echo "Running in a ramdisk"
```

## Tools

Given that we're starting from scratch, we don't have many
prerequisites, just a few small tools to make our life slightly
easier.

We'll be generating some config files from pre-written templates. For
this, we'll use `gotmpl`, a tiny templating tool.

```console
admin$ go install github.com/danderson/gotmpl
```

We'll be running Ceph on the cluster, so we'll need to install Ceph on
our admin machine as well, to get access to some of the tools for
things like key management. How to do so depends on your package
manager, so you're on your own here.

## Cluster directory

We'll want a directory in which to store some settings:

```console
admin$ mkdir ~/cluster
```

And the first thing we'll put in this directory is a copy of this
repository, so we can use its template files:

```console
admin$ git clone github.com/danderson/k8s-from-scratch ~/cluster/k8sfs
```

## Environment variables

We're going to be referring to a number of directories and names
during bringup, and to keep things fairly compact we're going to
define a few environment variables that we'll refer to in the
instructions.

To make it easier to source all the right things, we'll use a small
shell file to record variables:

```console
admin$ cp ~/cluster/k8sfs/files/env.sh ~/cluster/env.sh
admin$ source ~/cluster/env.sh
```

Keep a look out for other variables that we'll add to this file
throughout the bringup.
