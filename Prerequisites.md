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

The first is this repository, which contains a few prewritten files
that you can use. You're also welcome to write them yourself, of
course.

```console
admin$ git clone github.com/danderson/k8s-from-scratch
```

If you do want to use the prewritten files, you'll also need a tiny tool, `gotmpl`.

```console
admin$ go install github.com/danderson/gotmpl
```

If you're on another architecture, or prefer to build your own, you
can instead grab [the repository](https://github.com/danderson/gotmpl)
and build from that.

Finally, we'll want a directory in which to store a small number of files:

```console
admin$ mkdir ~/cluster
```

## Environment variables

We're going to be referring to a number of directories and names
during bringup, and to keep it generic we're going to define a few
environment variables that we'll refer to in the instructions.

```console
admin$ export CLUSTER_DIR=~/cluster
admin$ export K8SFS=~/k8s-from-scratch
```

Keep a look out for other variables that we'll define for some of the
steps.
