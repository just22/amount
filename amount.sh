#!/bin/sh

# ----------------------------------------------------------------------
#  $Id:$
#
#  Automatic MOUNTer for OpenBSD
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Copyright 2015-2020 Alessandro De Laurenzis
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ----------------------------------------------------------------------------

set -e
export PATH=/usr/bin:/bin/:/usr/sbin:/sbin

# Defaults
MROOT=/vol
MOPT=rw,nodev,nosuid,noatime
EXDEV=

usage() { cat 1>&2 <<- __USAGE__
	usage: ${0##*/} [-r path] [-g group] [-m mode] [-o opts] [-e dev ...]
	__USAGE__
        return 1
}

err() {
        [ -n "$1" ] && echo "${0##*/}: $1"
        return ${2:-1}
}

gsub() {
        s="$1"; p="$2"; v="$3"
        while [ "${s#*$p}" != "$s" ]; do
                s="${s%%$p*}$v${s#*$p}"
        done
        echo "$s"
}

echotty() {
        echo "$@" >/dev/tty
}

ret_mdir() {
        echo "$mdir"
}


# ----------------------------------------------------------------------
# Command line argument parsing
#
while getopts ":hr:g:m:o:e:" arg; do
        case "$arg" in
         r)  MROOT="$OPTARG" ;;
         g) MGROUP="$OPTARG" ;;
         m)  MMODE="$OPTARG" ;;
         o)   MOPT="$OPTARG" ;;
         e)  EXDEV="$OPTARG $EXDEV" ;;
         h) usage ;;
         :) err "Option -$OPTARG requires an argument" ;;
        \?) err "Unknown option: -$OPTARG"
        esac
done
shift $(($OPTIND - 1))


# ----------------------------------------------------------------------
# Variable description:
#   diskn = Disk name (dev:duid)
#     dev = Device name
#    desc = Disk description
#  diskid = Disk identifier (desc + label)
#   partf = Found (at least) a partition for a certain diskid
#   partn = Partition name
#   partt = Partition type
#  action = Mount/unmount
#

actno=0
for diskn in $(gsub $(sysctl -n hw.disknames) , \ ); do
        dev=${diskn%:*}
        [ "${EXDEV#*$dev}" == "$EXDEV" ] || continue

        unset partf

        disklabel -h "$dev" 2>/dev/null |&
        while read -p line; do
                case "$line" in
                disk:*)
                        desc="${line#disk:}"
                        ;;
                label:*)
                        diskid="${line#label:}${desc}"
                        diskid="${diskid## }"
                        echotty "Disk Id: $diskid ($dev)"
                        ;;
                a:*|d:*|e:*|f:*|g:*|h:*|i:*|j:*|k:*|l:*|m:*|n:*|o:*|p:*)
                        partf=
                        read partn partd _discard partt _discard <<- EOT
				$(echo "$line")
			EOT
                        partn=${partn%:*}

                        if [ "$partt" != "unknown" ]; then
                                let ++actno
                                mnt="$(mount)"
                                [ "${mnt#*${dev}${partn}}" != "$mnt" ] &&
                                    action="Unmount" ||
                                    action="  Mount"

                                menuitem="$action ${dev}${partn} $partt $partd"
                                echotty "$(printf "%2d:" "$actno") $menuitem"
                                set -- "$@" "$menuitem"
                        fi
                        ;;
                esac
        done
        if [ -n "${partf+set}" ]; then echotty; fi
done

if [ $# -eq 0 ]; then
        err "No devices"
elif [ $# -gt 9 ]; then
        err "Too many partitions"
fi

echotty -n "Select an action: "
read partsel

read action devpart partt _discard <<- EOT
	$(eval "echo \$$partsel")
EOT

mdir="${MROOT}/${devpart}"
case "$action" in
*Mount)
        [ -d "$mdir" ] || mkdir -p "$mdir"

        case "$partt" in
         4.2BSD) MOPT="-t ffs -o $MOPT"; RUN_FSCK= ;;
          MSDOS) MOPT="-t msdos -o $MOPT" ;;
         ext2fs) MOPT="-t ext2fs -o $MOPT" ;;
            UDF) MOPT="-t udf" ;;
        ISO9660) MOPT="-t cd9660" ;;
              *) err "Mount of $partt not supported"
        esac

        if [ -n "${RUN_FSCK+set}" ]; then
                if ! fsck -p -y /dev/"$devpart"; then
                        rm -r "$mdir"
                        err
                fi
        fi

        if ! mount $MOPT /dev/"$devpart" "$mdir"; then
                # Maybe a read-only fs? If not, give up
                if ! mount $MOPT -r /dev/"$devpart" "$mdir"; then
                        rm -r "$mdir"
                        err
                fi
        fi
        [ -n "$MGROUP" ] && chgrp "$MGROUP" "$mdir"
        [ -n "$MMODE" ]  && chmod "$MMODE"  "$mdir"

        ret_mdir
        ;;

Unmount)
        umount "$mdir"
        rm -r "$mdir"

        ret_mdir
        ;;
esac
