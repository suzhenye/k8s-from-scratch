# Collect Prerequisites

Given that we're starting from scratch, we don't have many
prerequisites, just a few small tools to make our life slightly
easier.

The first is this repository, which contains a few prewritten files
that you can use. You're also welcome to write them yourself, of
course.

```console
$ git clone github.com/danderson/k8s-from-scratch
```

If you do want to use the prewritten files, you'll also need a tiny tool, `gotmpl`. You can grab a prebuilt x86_64 binary from github:

```console
$ wget https://github.com/danderson/gotmpl/releases/download/v0.1/gotmpl
$ chmod +x gotmpl
```

If you're on another architecture, or prefer to build your own, you
can instead grab [the repository](https://github.com/danderson/gotmpl)
and build from that.

Finally, we'll want a directory in which to store a small number of files:

```console
$ mkdir mycluster
$ cd mycluster
```

It's a good idea to version control this directory, if you're into that:

```console
$ git init
Initialized empty Git repository in /home/dave/mycluster/.git/
```

Next, let's [bring up CoreOS](/CoreOS-Bringup.md).
