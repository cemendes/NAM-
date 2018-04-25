
#!/bin/bash

#Setting variables. The first two ones are retrieving the percentage in use of both archive and log volumes.
log_vol_size=`df -h /var/opt/novell | grep -oP  '\d+%' | cut -d '%' -f1`
archive_vol_size=`df -h /var/opt/novell/addittionalFS | grep -oP  '\d+%' | cut -d '%' -f1`
apache_dir=/var/log/novell-ag-logs/novell-apache2
tomcat_dir=/var/log/novell-ag-logs/maglogs
archive_dir=/var/opt/novell/addittionalFS
number_of_files=`ls | wc -l`
number_of_files_to_del=10
number_of_files_to_keep=`expr $number_of_files - $number_of_files_to_del`
archive_threshold=80
vol_threshold=80
log_file=/apps/NetIQ/tmp/move-nam-logs.log

if [[ $archive_vol_size -gt $vol_threshold ]]; then
   date >> $log_file
   echo "Removing logs from the archive directory" >> $log_file
   ls -td -1 $archive_dir/*.* | sed -e '1,30d' | xargs rm &>> $log_file
    if [[ $? != 0 ]]; then
       mail -r $HOSTNAME -s "There were problems removing logs from $archive_dir" carlos.mendes@microfocus.com < $log_file
    fi
fi
#Check if the process above was succesfull.

if [[ $log_vol_size -gt $vol_threshold ]]; then
   date >> $log_file
   echo "Moving logs to the archive directory" >> $log_file
   mv $apache_dir/*.gz $archive_dir &>> $log_file
   mv $tomcat_dir/*.gz $archive_dir &>> $log_file
    if [[ $? != 0 ]]; then
       mail -r $HOSTNAME -s "There were problems removing archives from /var/opt/novell" carlos.mendes@microfocus.com < $log_file
    fi
fi
