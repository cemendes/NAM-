#!/bin/bash

core_dir=/var/opt/novell/Apache_logs
core_gzip_dir=/var/opt/novell/addittionalFS
control=0

df -h

echo "#############################################################################################################"
read -p "Make sure $core_dir and $core_gzip_dir have at least 35GB of space available each. Press enter to continue"

for i in $(pgrep -f /opt/novell/apache2/sbin/httpd); do
		echo "Writting core for process $i"
        gcore -o $core_dir/core $i > /dev/null 2>&1
        gzip -c $core_dir/core.$i > $core_gzip_dir/core.$i.gz && rm -f $core_dir/core.$i &

       done
echo "###############################################################"
echo "Apache can be restarted at this point. All cores were collected"
echo "###############################################################"

        #checking if there are gzip cmds waiting to finish

        while [[ $control == 0 ]]; do
        	 pgrep -f 'gzip -c /var/opt/novell/Apache_logs/core' > /dev/null 2>&1

        	 if [[ $? = 1 ]]; then
        	 	echo "Done zipping up the core files. They can be found at $core_gzip_dir/core*"
        	  	exit 0
        	 fi

        	 echo "Waiting for core files to be zipped up..."
        	 sleep 10
        	done


 