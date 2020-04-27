#!/bin/bash
TOPDIR=`git rev-parse --show-toplevel`
ls *.sh | grep -v "createSymlink.sh" | sort | while read filename
  do
    echo "Creating symlink to $filename"
    shortcut=`echo $filename | sed "s/.sh//g"`
    rm -f /usr/local/bin/$shortcut
    ln -s  $TOPDIR/$filename /usr/local/bin/$shortcut
    echo "    $filename --> /usr/local/bin/$shortcut"
  done