#!/bin/bash
httpd_process_count=`pgrep -f /opt/novell/apache2/sbin/httpd | wc -l`
echo "There are $httpd_process_count httpd processes running on this box"

for i in $(pgrep -f /opt/novell/apache2/sbin/httpd); do
        thread_count=`ps huH -p $i | wc -l`
        if [[ "$(($thread_count))" -gt "300" ]]; then
                tac $1 | fgrep -m1  "[$i" > /dev/null 2>&1
                ctrl=$?
                 if [[ "$(($ctrl))" -eq "0" ]]; then
                        tac $1| fgrep -m1  "[$i" | cut -d' ' -f 1-6
                else
                  echo "PID" $i "not found"
                 
                fi
        fi

       
done

