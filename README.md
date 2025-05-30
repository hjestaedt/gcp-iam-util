# gcp iam util

a shell script for working with GCP IAM resources.

## features

- roles:
  - is-subset: check if permissions of one role are a subset of one or more other roles
  - get-permissions: extract and list permissions from one or more roles

## installation

### quick Install

install to `$HOME/bin` (default):

```bash
make install
```

### custom Install Directory

install to a custom directory:

```bash
make install-to DIR=/usr/local/bin
```

Or set the default install directory:

```bash
make INSTALL_DIR=/opt/bin install
```

## usage

### roles command

#### is-subset subcommand

```bash
gcp-iam-util roles is-subset roles/viewer roles/editor
```

#### get-permissions subcommand

```bash
gcp-iam-util roles get-permissions roles/editor
```