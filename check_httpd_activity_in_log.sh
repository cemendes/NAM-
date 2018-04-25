#!/bin/bash
date30=$(date -d 'now - 30 minutes'  +%e\ %R)
csplit_date=$(echo /${date30:0:2}\\${date30:2:3}\\${date30:5:4}.*$/)
httpd_process_count=`pgrep -f /opt/novell/apache2/sbin/httpd -u wwwrun | wc -l`
log=/apps/NetIQ/log/check_httpd_activity_in_log.log
tmp_error_log=/var/opt/novell/Apache_logs/error_log_tmp01
count=0
error_log=/var/opt/novell/Apache_logs/error_log
error_log_tmp=$error_log\_tmp
log_dir=/var/opt/novell/Apache_logs
last_archive_gz=$(ls -tr /var/opt/novell/Apache_logs/error_log-20*.gz | tail -1)
last_archive=$(echo ${last_archive_gz%???})
exit_status=''


## Merge actual error_log and its latest archive and create a new file with only the last 30 minutes of activity

    gunzip < $last_archive_gz > $last_archive
    cat $error_log > $error_log_tmp
    cat $error_log_tmp >> $last_archive
    read -p "press enter"
    csplit -f $log_dir/error_log_tmp $last_archive "$csplit_date"
    exit_status=$?
    rm -f $last_archive


# #if the cmd above fails, look in the latest archive created
# if [[ $? = 1 ]]; then
#     gunzip < $last_archive_gz > $last_archive
#     csplit -f $log_dir/error_log_tmp $last_archive "$csplit_date"
#     exit_status=$?
#     rm -f $last_archive

if [[ $exit_status = 1 ]]; then
    #statements
    echo "######################################################" >> $log
    date >> $log
    echo "Failed to find the time frame $date30 both in error_log and on the latest error_log archive" >> $log
    echo "######################################################" >> $log
    echo -e \\n >> $log
    exit 1

    
fi
#echo "There are $httpd_process_count httpd processes running on this box"

for i in $(pgrep -f /opt/novell/apache2/sbin/httpd -u wwwrun); do
                tac $tmp_error_log | fgrep -m1  "[$i" > /dev/null 2>&1
                ctrl=$?
                 if [[ "$(($ctrl))" -eq "1" ]]; then
                  count=$((count + 1))

                fi

done


##Cleaning up
rm -f /var/opt/novell/Apache_logs/error_log_tmp01
rm -f /var/opt/novell/Apache_logs/error_log_tmp00


echo "######################################################" >> $log
date >> $log
echo "There is/are $count of httpd processes dormant" >> $log
echo "######################################################" >> $log
echo -e \\n >> $log


if [[ "$count" -gt "5" ]]; then
        echo "Restart apache using rcnovell-apache stop/start. Make sure apache is completely stopped before starting it." |  mail -r $HOSTNAME -s "this server has at least $count httpd proc dormant." carlos.mendes@microfocus.com,tony.calderone@microfocus.com,jeremy.franz@alight.com,blair.underwood@aon.com,mohit.sharma.10@Aonhewitt.com
fi
