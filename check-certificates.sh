#!/bin/bash

# This script perform three tasks:
# 1 - Searchs the configuration store for certificates
# 2 - Transform the date from a 12 digit format to a 8 digit format
# 3 - Check if the expiration date of the certificates is going to happen in 30 days or less. if so, email the admin.

ldapsearch -Dcn=admin,o=novell -w novell -h localhost -bo=novell objectclass=nDSPKIKeyMaterial nDSPKINotAfter > certificates.txt

Step 2
sed '/nDSPKINotAfter/s/.\{6\}$//g' certificates.txt > certificatesv2.txt
