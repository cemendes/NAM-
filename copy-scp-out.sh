#!/bin/bash
while read dest; do
    echo $dest
scp -P $2 $1 ${dest}:/apps/NetIQ/scripts
done
