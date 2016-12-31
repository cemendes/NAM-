#!/bin/bash
while read dest; do
ping -n 1 $dest
done
