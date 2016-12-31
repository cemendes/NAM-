#!/bin/bash
while read dest; do
scp -v -P 2222 $1 ${dest}:/home/a0688697/
done
