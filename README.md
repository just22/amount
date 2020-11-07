AMOUNT(1) - General Commands Manual

# NAME

**amount** - Minimalist (semi)automatic mounter for OpenBSD

# SYNOPSIS

**amount**
\[**-r**&nbsp;*path*]
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
so it should be run through
doas(1).

After a successful operation,
**amount**
returns the path of the mount point on stdout (for unmount
operations, the directory is removed before exiting and no longer
exists).

The options are as follows:

**-r** *path*

> Set root mount directory to path; path must exist and have the proper
> permissions (defaults to /vol).

**-o** *options*

> Mount options (defaults to rw,nodev,nosuid,noatime).

**-e** *device ...*

> The listed devices will be ignored.

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
	        mdir="$(/usr/bin/doas /usr/local/bin/amount)"
	        [ $? -ne 0 ] && keep
	        clear
	        [ -d "$mdir" ] && filemanager "$mdir"
	done

# SEE ALSO

disklabel(8),
doas(1),
fsck(8,)
mount(8),
umount(8)

# AUTHORS

**amount**
was written by Alessandro De Laurenzis &lt;just22@atlantide.mooo.com&gt;
