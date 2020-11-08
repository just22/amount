AMOUNT(1) - General Commands Manual

# NAME

**amount** - minimalist (semi)automatic mounter for OpenBSD

# SYNOPSIS

**amount**
\[**-r**&nbsp;*path*]
\[**-g**&nbsp;*group*]
\[**-m**&nbsp;*mode*]
\[**-o**&nbsp;*options*]
\[**-e**&nbsp;*device&nbsp;...*]

# DESCRIPTION

**amount**
is an
OpenBSD
specific, POSIX compliant shell script to manage removable devices;
it presents a list of available partitions, and (un)mount them upon
user request.
A few commands used by
**amount**
require special permissions
(mount(8),
umount(8),
disklabel(8),
fsck(8) ...),
so it should be run as root.

After a successful operation,
**amount**
returns the path of the mount point on stdout (for unmount
operations, the directory is removed before exiting and no longer
exists).

The options are as follows:

**-r** *path*

> Set root mount directory to path; path must exist and have the proper
> permissions (defaults to /vol).

**-g** *group*

> Set group ownership for mount directory.

**-m** *mode*

> Set file mode, as in
> chmod(1),
> for mount directory.

**-o** *options*

> Mount options (defaults to rw,nodev,nosuid,noatime).

**-e** *device ...*

> The listed devices will be ignored.

# CAVEATS

Changing mount directory ownership and file mode are not supported for
read-only filesystems (e.g., ISO9660 partitions).

**amount**
emulates arrays by means of positional parameters, so it cannot manage
more than 9 partitions at a time; this limitation can be overcome using
the -e option, except when a single device by itself exceeds the
maximum number of partitions.

# EXAMPLES

A simple wrapper around
**amount**
will allow the use of a filemanager, as well as endless mount/unmount
iterations:

	#!/bin/sh
	
	keep() {
	        stty raw
	        dd bs=1 count=1 2> /dev/null
	        stty -raw
	}
	
	clear
	while : ; do
	        mdir="$(/usr/bin/doas amount)"
	        [ $? -ne 0 ] && keep
	        clear
	        [ -d "$mdir" ] && filemanager "$mdir"
	done

# SEE ALSO

disklabel(8),
doas(1),
fsck(8),
mount(8),
umount(8)

# AUTHORS

**amount**
was written by Alessandro De Laurenzis &lt;just22@atlantide.mooo.com&gt;
