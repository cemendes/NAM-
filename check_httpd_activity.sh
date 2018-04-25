#!/bin/bash
log_dir=/var/opt/novell/Apache_logs/$HOSTNAME\_strace
mkdir -p $log_dir
thread_count=""


## Gzip all files in the directory if not straces are running
pgrep strace
if [[ "$?" -ne "0" ]]; then
        gzip $log_dir/*.txt > /dev/null 2>&1
fi

for i in $(pgrep -f /opt/novell/apache2/sbin/httpd); do
                thread_count=`ps huH -p $i | wc -l`
                lock_wait=`gstack $i | grep lll_lock_wait | wc -l`
                if [[ "$thread_count" -gt "300" && "$((lock_wait))" -eq "0" ]]; then
                    timeout 120 strace -f -s1000 -o $log_dir/httpd-strace-pid$i-`date +'%Y%m%d-%H%M'`.txt -p $i
                        #tac /var/opt/novell/nam/logs/mag/apache2/error_log | fgrep -m1  "[$i" > /dev/null 2>&1
                fi


         done
