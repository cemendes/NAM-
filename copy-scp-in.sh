#!/bin/bash
while read dest; do
    echo $dest
scp -P 2222 ${dest}:/var/opt/novell/debug/$1 ../Issues/
done
