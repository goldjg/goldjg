#!/usr/bin/perl
##-------------------------------------------------------------------------
##
## Title:               delete_diskgroup.pl
##
## Submitter:           ##REDACTED##
## Submittter Email:    ##REDACTED##
## Date:                5/21/08
##
## Description:         This script performs the BCV establish and split for the operators
##
## Usage:               ./delete_diskgroup.pl
##
## Version history:
## 1.0 - Initial release
## 1.1 - Add extra dev and dev group
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
my $DG_DEVS = 76 ;

if ($DG_NAME !~ /^(BCV|BCV)$/){
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
## Main program actions
##-------------------------------------------------------------------------

print `/usr/symcli/bin/symmir -g $DG_NAME query`;
my $D_RC = $?;

