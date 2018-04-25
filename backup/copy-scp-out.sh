#!/bin/bash
while read dest; do
    echo $dest
scp -P 2222 $1 ${dest}:/home/a0688697/
done
