#!/usr/bin/perl
##-------------------------------------------------------------------------
##
## Title:               Unisys_BCV.pl
##
## Submitter:           ##REDACTED##
## Submittter Email:    ##REDACTED##
## Date:                5/15/08
##
## Description:         This script performs the BCV establish and split ##REDACTED##
##
## Usage:               ./Unisys_BCV.pl
##
## Version history:
## 1.0 - Initial release
## Enter_script_authtor - Enter_script_creation_date
##
############################################################

use strict;;

##-------------------------------------------------------------------------
## Initial setting being here
##-------------------------------------------------------------------------
my $version = "1.0";
$0 =~ /(.*\/)(.*)/;                     # Strips off the script name and sets the directory path
my $progname = $2;                      # Strips off the script path and sets PGM
my $pathname = $1;                      # Strips off the script path and sets PGM
my $PGM = "$pathname/$progname";

##-------------------------------------------------------------------------
##Global variables
##-------------------------------------------------------------------------
my $DG_NAME = $ARGV[0] ;
my $DG_DEVS = 75 ;

if ($DG_NAME !~ /^(##REDACTED##|##REDACTED##|##REDACTED##|##REDACTED##)$/){
		 print "Unacceptable disk group name: $DG_NAME\n";
		 exit 99;
}
#print $DG_NAME;

##-------------------------------------------------------------------------
## Logic to display version with a command line option
##-------------------------------------------------------------------------
if ($ARGV[0] eq "-v")
{
        print "${pathname}$progname - Version: $version\n";
        exit 10
}

##-------------------------------------------------------------------------
## Step 1 - Validate BCV Disk Group
##-------------------------------------------------------------------------

##
#Run a symdg list and write it into an array
##
my @DG_LIST = `/usr/symcli/bin/symdg list` ;   
my $found = 0;

##
#Loop through the array until you match a line with the $DG_Name in it
##
foreach my $line (@DG_LIST) {
   if ($line =~ /$DG_NAME\s+.*/) {
 
   ##
   #If the line matches, set the value of $found to 1, and compare the 5th field to the amount of devices
   #expected in the disk group
   ##
       $found = 1;
       chomp $line ;
       my @fields = split /\s+/, $line ;
       if ( $DG_DEVS ne $fields[5] ) {
         ##
         #If the device count does not match error, else OK
         ##
         print "ERROR:  The diskgroup $DG_NAME exists, but only has $fields[5] devices.  It is expected to have $DG_DEVS\n";
         exit 10 ;
       }
       print "OK:     The diskgroup $DG_NAME exists and has the expected number of devices ($DG_DEVS)\n";
   }
}
##
#If we reach the end of the symdg list and have not matched the Device Group, error
#At this point in the procedure the operator is told to do a symdg -force delete on any DG that has 75 devices and BCVs
#and then recreate the proper disk group.  These actions need to be formalized and scripted/output here.
##
if ($found eq 0) {
  print "ERROR:  The diskgroup $DG_NAME does not exist\n";
  exit 11;
}

##-------------------------------------------------------------------------
## Step 2 - Verify BCV Disk Group state
##-------------------------------------------------------------------------

##
#Run a symmir verify -split to see if the disks are in the correct split state
#Check the return code, valid return codes are 0 split, 25 partially split and 26 none are split
##

`/usr/symcli/bin/symmir -g $DG_NAME verify -split`;
my $RC = $? >> 8;

if ($RC eq 0) {
   print "OK:     The diskgroup is in the split state as expected\n";
}
elsif ($RC eq 25) {
   print "Error:  The diskgroup is partially split\n";
   exit 25;
}
elsif ($RC eq 26) {
   print "Error:  The diskgroup has no devices in the split state\n";
   exit 26;
}
else {
   print "Error:  The diskgroup verify split command returned an unknown return code of $RC\n";
   exit 29;
}


##-------------------------------------------------------------------------
## Step 3 - Establish BCV
##-------------------------------------------------------------------------

##
#Run a symmir establish command
##
`sleep 60`;
`/usr/symcli/bin/symmir -sid #### -g $DG_NAME establish -nop`;
my $EST_RC = $? >> 8;

##
#Check the return code, 0 worked, non 0 is an error
##

if ($EST_RC eq 0) {
   print "OK:     The establish completed successfully\n";
}
else {
   print "Error:  The establish command returned a failure, return code was $EST_RC\n";
   exit 30 ;
}

##-------------------------------------------------------------------------
## Step 4 - Monitor BCV
##-------------------------------------------------------------------------

##
#Run a symmir verify -synced -i 120 -c 120
#That runs the verify every 2 minutes 120 times (4 hours).  If the disks report synched in the 
#4 hours, it will drop out with a 0 return code.  If the 4 hours expires and they are not synched
#It will drop out with a non-zero return code.
##
`sleep 60`;
`/usr/symcli/bin/symmir -g $DG_NAME verify -synched -i 120 -c 120`;
my $VS_RC = $? >> 8;

if ($VS_RC eq 0) {
   print "OK:     The diskgroup has fully copied.  Continueing with the Split\n";
}
else {
   print "Error:  The diskgroup has not copied in 4 hours.  This should take less than an hour\n";
   exit 40;
}


##-------------------------------------------------------------------------
## Step 5 - Split BCV
##-------------------------------------------------------------------------

##
#If we are here the sync completed successfully 
#Run a symmir split command, check the return code, 0 is success, >0 is fail
##
`sleep 60`;
`/usr/symcli/bin/symmir -sid #### -g $DG_NAME split -nop`;
my $SP_RC = $? >> 8;

if ($SP_RC eq 0) {
   print "OK:     The split completed successfully\n";
}
else {
   print "Error:  The split command returned a failure, return code was $SP_RC\n";
   exit 50 ;
}


##-------------------------------------------------------------------------
## Step 6 - Verify Split
##-------------------------------------------------------------------------

##
#Run a symmir verify -split to see if the disks are in the correct split state
#Check the return code, valid return codes are 0 split, 25 partially split and 26 none are split
##
`sleep 60`;
`/usr/symcli/bin/symmir -g $DG_NAME verify -split`;
my $V_RC = $?;

if ($V_RC eq 0) {
   print "OK:     The diskgroup is in the split state as expected\n";
   print "OK:     The Extract Data Refresh process has completed successfully.\n";
}
elsif ($V_RC eq 25) {
   print "Error:  The diskgroup is partially split\n";
   exit 25;
}
elsif ($V_RC eq 26) {
   print "Error:  The diskgroup has no devices in the split state\n";
   exit 26;
}
else {
   print "Error:  The diskgroup verify split command returned an unknown return code of $V_RC\n";
   exit 29;
}
