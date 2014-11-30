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

If you do want to use the prewritten files, you'll also need a tiny tool, `gotmpl`. You can grab a prebuilt x86_64 binary from github:

```console
admin$ wget https://github.com/danderson/gotmpl/releases/download/v0.1/gotmpl
admin$ chmod +x gotmpl
```

If you're on another architecture, or prefer to build your own, you
can instead grab [the repository](https://github.com/danderson/gotmpl)
and build from that.

Finally, we'll want a directory in which to store a small number of files:

```console
admin$ export CDIR=~/mycluster
admin$ mkdir $CDIR
admin$ cd $CDIR
```

It's a good idea to version control this directory, if you're into that:

```console
admin$ git init
Initialized empty Git repository in /home/dave/mycluster/.git/
```

Next, let's [bring up CoreOS](/CoreOS-Bringup.md).
