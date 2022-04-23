#!/usr/bin/perl
##-------------------------------------------------------------------------
##
## Title:               Unisys_Dev_Status_Check.pl
##
## Submitter:           Graham Gold
## Submittter Email:    ##REDACTED##
## Date:                08/03/11
##
## Description:         This script checks the status of the ##REDACTED## disks
##
## Usage:               ./Unisys_Dev_Status_Check.pl
##
## Version history:
## 1.0 - Initial release
##
############################################################

use strict;;

##-------------------------------------------------------------------------
## Initial settings here
##-------------------------------------------------------------------------
my $version = "1.0";
$0 =~ /(.*\/)(.*)/;                     # Strips off the script name and sets the directory path
my $progname = $2;                      # Strips off the script path and sets PGM
my $pathname = $1;                      # Strips off the script path and sets PGM
my $PGM = "$pathname/$progname";


##-------------------------------------------------------------------------
## Check Sync state
##-------------------------------------------------------------------------

##
#Run a symrdf verify -synchronized
#If the disks report synched in the symrdf verify will drop out with a 0 return code
#otherwise it will drop out with a non-zero return code.
##

`/usr/symcli/bin/symrdf -sid #### -f ##REDACTED##.map -rdfg ## verify -synchronized`;
my $VS_RC = $? >> 8;

if ($VS_RC eq 0) {
   `echo $VS_RC | /usr/bin/mail -r $(hostname) -s "INFO: ##REDACTED## EMC Disks are in Synchronized state." graham.gold\@domain`;
   exit 0;
}
elsif ($VS_RC eq 4) {
   `echo $VS_RC | /usr/bin/mail -r $(hostname) -s "WARNING: Not all ##REDACTED## EMC Disks are in Synchronized state." graham.gold\@domain`;
   exit 10;
}
elsif ($VS_RC eq 5) {
   `echo $VS_RC | /usr/bin/mail -r $(hostname) -s "WARNING: No ##REDACTED## EMC Disks are in Synchronized state." graham.gold\@domain`;
   exit 20;
}
else {
   `echo $VS_RC | /usr/bin/mail -r $(hostname) -s "WARNING: Unexpected result querying ##REDACTED## EMC Disks." graham.gold\@domain`;
   exit 30;
}



