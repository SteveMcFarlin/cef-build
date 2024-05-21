#!/bin/bash
set -e

for f in $(find cef-build/chromium/src/cef/binary_distrib -name "*.tar.bz2")
do
    echo $f
    sha1sum $f | cut -d' ' -f1 > $f.sha1
done