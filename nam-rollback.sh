#!/bin/bash -x

my_date=`/bin/date +%Y%m%d-%-k%M`
backup_dir=/apps/NetIQ/backupMF/nam-config-$HOSTNAME-$my_date
main_backup_dir=/apps/NetIQ/backupMF
nds_include=$backup_dir/ndsbackup-include-$HOSTNAME.txt
nds_backup_file=$backup_dir/ndsbackup-$HOSTNAME.nds
ldif_file=$backup_dir/trustee-$HOSTNAME.ldif
nds_backup_cmd=/opt/novell/eDirectory/bin/ndsbackup
cp_cmd="/bin/cp -vR"
diff_cmd="/usr/bin/diff -qr"

set_backup_dir () {
    echo "Here are the backup directories found"
    echo "#############################################################################"
    ls -ltr $main_backup_dir
    echo "#############################################################################"
    sleep 1
    echo "Enter the backup directory name."
    read restore_backup_dir
    sleep 1
    clear
}

create_dir () {
mkdir -p $backup_dir/jsp
mkdir -p $backup_dir/extra
mkdir -p $backup_dir/WEB-INF/config
}

warning_msg () {
    # prompt='n'
    echo
    echo "One can only use the restore option after rolling back a failed NAM upgrade. DO NOT USE TO RESTORE CONFIGURATION AFTER AN UPGRADE"
    read -e -p "Would you like to continue with the restore (y/n) ?" prompt
    if [ -z $prompt ]
     then prompt='n'
    fi
    if [ $prompt != 'y' -a $prompt != 'Y' ]
        then
        read -e -p "Terminating Restore. Press CTRL+C"


    fi
}


backup_idp () {
    create_dir
    echo "Backing up configuration files "
    $cp_cmd /opt/novell/nids/lib/webapp/WEB-INF/classes/kerb.properties $backup_dir
    $cp_cmd /opt/novell/java/jre/lib/security/bcsLogin.conf $backup_dir
    $cp_cmd /opt/novell/java/jre/lib/security/nidpkey.keytab $backup_dir
    $cp_cmd /opt/novell/nids/lib/webapp/WEB-INF/classes/nidpconfig.properties $backup_dir
    $cp_cmd /opt/novell/nam/idp/webapps/nidp/jsp/* $backup_dir/jsp/
    $cp_cmd /opt/novell/nam/idp/conf/tomcat.conf $backup_dir
    $cp_cmd /opt/novell/nam/idp/conf/server.xml $backup_dir
    $cp_cmd /opt/novell/nam/idp/conf/logrotate.conf $backup_dir
    $cp_cmd /opt/novell/nam/idp/conf/logrotate.conf $backup_dir
    $cp_cmd /etc/rsyslog.d/nam.conf $backup_dir

    echo "Done backing up configuration files"
}

backup_ag () {
    create_dir
    echo "Backing up configuration files"
    $cp_cmd /opt/novell/nam/mag/webapps/nesp/jsp/* $backup_dir/jsp
    $cp_cmd /etc/opt/novell/apache2/conf/httpd.conf $backup_dir
    $cp_cmd /etc/opt/novell/apache2/conf/extra/* $backup_dir/extra
    $cp_cmd /opt/novell/nam/mag/conf/tomcat.conf $backup_dir/
    $cp_cmd /opt/novell/nam/mag/conf/server.xml $backup_dir/
    $cp_cmd /opt/novell/nam/mag/conf/logrotate.conf $backup_dir
    $cp_cmd /opt/novell/nam/mag/conf/logrotate.conf $backup_dir
    $cp_cmd /etc/init.d/novell-apache2 $backup_dir
    $cp_cmd /etc/rsyslog.d/nam.conf $backup_dir
    echo "Done backing up configuration files"

}

backup_ac () {
    create_dir
    echo "Backing up configuration files "
    $cp_cmd /opt/novell/nam/adminconsole/conf/server.xml $backup_dir/
    $cp_cmd /opt/novell/nam/adminconsole/webapps/nps/WEB-INF/config.xml $backup_dir/
    $cp_cmd /var/opt/novell/iManager/nps/portal/modules/fw/images/iMan27_H1_L0.gif $backup_dir/
    $cp_cmd /var/opt/novell/iManager/nps/WEB-INF/configiman.properties $backup_dir/
    $cp_cmd /var/opt/novell/iManager/nps/WEB-INF/config/* $backup_dir/WEB-INF/config
    $cp_cmd /opt/novell/nam/adminconsole/conf/logrotate.conf $backup_dir/
    $cp_cmd /opt/novell/nam/adminconsole/conf/tomcat7.conf $backup_dir
    $cp_cmd /opt/novell/nam/adminconsole/conf/logrotate.conf $backup_dir/logrotate.conf-novell-ac
    $cp_cmd /opt/volera/roma/conf/logrotate.conf $backup_dir/logrotate.conf-novell-devman
    $cp_cmd /etc/rsyslog.d/nam.conf $backup_dir
    echo "Done backing up configuration files"
    sleep 1

    echo "Searching for the user accounts in eDirectory. Wait 5 seconds and enter your admin password"
    ldapsearch -h localhost -b o=novell -Dcn=admin,o=novell -W  -s one objectclass=user | grep -i dn: | grep -vE cn=admin | cut -d ':' -f2 | sed 's/,/./g' > $nds_include
    cat $nds_include
    sleep 1

    echo "Backing up users trustees"
    rm -f $backup_dir/ACL_backup-$HOSTNAME-ldif 2<&1
    echo "dn: t="$HOSTNAME"_tree" >> $ldif_file
    echo "changetype: modify" >> $ldif_file
    echo "add: acl" >> $ldif_file
    for i in $(cat $nds_include | sed 's/.o=/,o=/g'); do
      echo "acl: 17#subtree#"$i"#[Entry Rights]" >> $ldif_file
      echo "acl: 13#subtree#"$i"#[All Attributes Rights]" >> $ldif_file
    done
    echo "Done Backing up user trustees"
    sleep 1

    echo "Using ndsbackup to backup all users accounts from the AC tree. The admin password will be requested..."
    $nds_backup_cmd cvf $nds_backup_file -a admin.novell -I $nds_include
    echo "Done backing up the user accounts"
    echo "Backup Directory is located at" $backup_dir
}

restore_ac () {
    warning_msg
    echo "About to restore the AC user accounts and configuration files..."
    set_backup_dir
    echo "#############################################################################"
    echo "Using ndsbackup to restore the user accounts."
    echo "Enter the admin password"
    echo "#############################################################################"
    $nds_backup_cmd xvf $main_backup_dir/$restore_backup_dir/ndsbackup-$HOSTNAME.nds -a admin.novell -I $main_backup_dir/$restore_backup_dir/ndsbackup-include-$HOSTNAME.txt
    echo "Done restoring the user accounts"

    sleep 1
    echo "Restoring user trustees. Here are the ldif files found."
    /usr/bin/ldapmodify -v -h  localhost -Dcn=admin,o=novell -W -f $main_backup_dir/$restore_backup_dir/trustee-$HOSTNAME.ldif
    echo "#############################################################################"
    echo "Done restoring user trustees"

    echo "Restoring configuration files."
    sleep 1
    echo "#############################################################################"
    $cp_cmd $main_backup_dir/$restore_backup_dir/server.xml /opt/novell/nam/adminconsole/conf/server.xml
    $cp_cmd $main_backup_dir/$restore_backup_dir/config.xml /opt/novell/nam/adminconsole/webapps/nps/WEB-INF/config.xml
    $cp_cmd $main_backup_dir/$restore_backup_dir/iMan27_H1_L0.gif /var/opt/novell/iManager/nps/portal/modules/fw/images/iMan27_H1_L0.gif
    $cp_cmd $main_backup_dir/$restore_backup_dir/configiman.properties /var/opt/novell/iManager/nps/WEB-INF/configiman.properties
    $cp_cmd $main_backup_dir/$restore_backup_dir/WEB-INF/config/* /var/opt/novell/iManager/nps/WEB-INF/config/
    $cp_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf /opt/novell/nam/adminconsole/conf/logrotate.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/tomcat7.conf /opt/novell/nam/adminconsole/conf/tomcat7.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf-novell-devman /opt/volera/roma/conf/logrotate.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf-novell-ac /opt/novell/nam/adminconsole/conf/logrotate.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/nam.conf /etc/rsyslog.d/nam.conf
    echo "#############################################################################"
    echo "Done restoring the configuration fies"
    sleep 1

    echo "#############################################################################"
    echo "Restarting the ACs iManager"
    /etc/init.d/novell-ac restart
    echo "Done"

}

restore_idp () {
    warning_msg
    set_backup_dir
    echo "Restoring IDP configuration files "
    $cp_cmd $main_backup_dir/$restore_backup_dir/kerb.properties /opt/novell/nids/lib/webapp/WEB-INF/classes/kerb.properties
    $cp_cmd $main_backup_dir/$restore_backup_dir/bcsLogin.conf /opt/novell/java/jre/lib/security/bcsLogin.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/nidpkey.keytab /opt/novell/java/jre/lib/security/nidpkey.keytab
    $cp_cmd $main_backup_dir/$restore_backup_dir/nidpconfig.properties /opt/novell/nids/lib/webapp/WEB-INF/classes/nidpconfig.properties
    $cp_cmd $main_backup_dir/$restore_backup_dir/jsp/* /opt/novell/nam/idp/webapps/nidp/jsp/
    $cp_cmd $main_backup_dir/$restore_backup_dir/tomcat.conf /opt/novell/nam/idp/conf/tomcat.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/server.xml /opt/novell/nam/idp/conf/server.xml
    $cp_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf /opt/novell/nam/idp/conf/logrotate.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/nam.conf /etc/rsyslog.d/nam.conf
    echo "Done restoring IDP configuration files"
    sleep 2
    echo "Restarting the IDP"
    /etc/init.d/novell-idp restart

}

restore_ag () {
    warning_msg
    set_backup_dir
    echo "Restoring AG configuration files "
    $cp_cmd $main_backup_dir/$restore_backup_dir/jsp/* /opt/novell/nam/mag/webapps/nesp/jsp/
    $cp_cmd $main_backup_dir/$restore_backup_dir/httpd.conf /etc/opt/novell/apache2/conf/httpd.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/extra/* /etc/opt/novell/apache2/conf/extra/
    $cp_cmd $main_backup_dir/$restore_backup_dir/tomcat.conf /opt/novell/nam/mag/conf/tomcat.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/server.xml /opt/novell/nam/mag/conf/server.xml
    $cp_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf /opt/novell/nam/mag/conf/logrotate.conf
    $cp_cmd $main_backup_dir/$restore_backup_dir/novell-apache2 /etc/init.d/novell-apache2
    $cp_cmd $main_backup_dir/$restore_backup_dir/nam.conf /etc/rsyslog.d/nam.conf
    echo "Done restoring AG configuration files"
    sleep 2
    echo "Restarting all NAM services"
    /etc/init.d/novell-appliance restart
}

#copy_files /opt/novell/nids/lib/webapp/WEB-INF/classes/kerb.properties

compare_idp () {
    echo "Comparing configuration files for the IDP"
    set_backup_dir
    $diff_cmd $main_backup_dir/$restore_backup_dir/kerb.properties /opt/novell/nids/lib/webapp/WEB-INF/classes/kerb.properties
    $diff_cmd $main_backup_dir/$restore_backup_dir/bcsLogin.conf /opt/novell/java/jre/lib/security/bcsLogin.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/nidpkey.keytab /opt/novell/java/jre/lib/security/nidpkey.keytab
    $diff_cmd $main_backup_dir/$restore_backup_dir/nidpconfig.properties /opt/novell/nids/lib/webapp/WEB-INF/classes/nidpconfig.properties
    $diff_cmd $main_backup_dir/$restore_backup_dir/jsp/ /opt/novell/nam/idp/webapps/nidp/jsp/
    $diff_cmd $main_backup_dir/$restore_backup_dir/tomcat.conf /opt/novell/nam/idp/conf/tomcat.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/server.xml /opt/novell/nam/idp/conf/server.xml
    $diff_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf /opt/novell/nam/idp/conf/logrotate.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/nam.conf /etc/rsyslog.d/nam.conf
    echo "Done comparing configuration files. Any files listed above need to be compared manually"
}

compare_ac () {
    echo "Comparing configuration files for the AC"
    set_backup_dir
    $diff_cmd $main_backup_dir/$restore_backup_dir/server.xml /opt/novell/nam/adminconsole/conf/server.xml
    $diff_cmd $main_backup_dir/$restore_backup_dir/config.xml /opt/novell/nam/adminconsole/webapps/nps/WEB-INF/config.xml
    $diff_cmd $main_backup_dir/$restore_backup_dir/iMan27_H1_L0.gif /var/opt/novell/iManager/nps/portal/modules/fw/images/iMan27_H1_L0.gif
    $diff_cmd $main_backup_dir/$restore_backup_dir/configiman.properties /var/opt/novell/iManager/nps/WEB-INF/configiman.properties
    $diff_cmd $main_backup_dir/$restore_backup_dir/WEB-INF/config/ /var/opt/novell/iManager/nps/WEB-INF/config/
    $diff_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf /opt/novell/nam/adminconsole/conf/logrotate.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/tomcat7.conf /opt/novell/nam/adminconsole/conf/tomcat7.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf-novell-devman /opt/volera/roma/conf/logrotate.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf-novell-ac /opt/novell/nam/adminconsole/conf/logrotate.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/nam.conf /etc/rsyslog.d/nam.conf
    echo "Done comparing configuration files. Any files listed above need to be compared manually"
}

compare_ag () {
    echo "Comparing configuration files for the AG"
    set_backup_dir
    $diff_cmd $main_backup_dir/$restore_backup_dir/jsp/ /opt/novell/nam/mag/webapps/nesp/jsp/
    $diff_cmd $main_backup_dir/$restore_backup_dir/httpd.conf /etc/opt/novell/apache2/conf/httpd.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/extra/ /etc/opt/novell/apache2/conf/extra/
    $diff_cmd $main_backup_dir/$restore_backup_dir/tomcat.conf /opt/novell/nam/mag/conf/tomcat.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/server.xml /opt/novell/nam/mag/conf/server.xml
    $diff_cmd $main_backup_dir/$restore_backup_dir/logrotate.conf /opt/novell/nam/mag/conf/logrotate.conf
    $diff_cmd $main_backup_dir/$restore_backup_dir/novell-apache2 /etc/init.d/novell-apache2
    $diff_cmd $main_backup_dir/$restore_backup_dir/nam.conf /etc/rsyslog.d/nam.conf
    echo "Done comparing configuration files. Any files listed above need to be compared manually"
}