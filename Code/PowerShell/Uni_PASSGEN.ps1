<#
##################################################################################
# Password Generator for MF                             #
# ==================================================                             #
# Generates password for use in ##REDACTED## for a TCP host and generates       #
# an Outlook email with the password in the body, and sensitivity set to private #
# (to ensure the email is encrypted) for sharing with the batch or server team.  #
#                                                                                #
# There must be a local ##REDACTED## usercode on the remote windows or Unisys server #
# with the password set the same as is stored in ##REDACTED##.                         #
#                                                                                #
# Will generate password matching the following guidelines:                      #
#  - Between 8 and 11 characters in length                                       #
#  - Contains Uppercase Letters                                                  #
#  - Contains Digits 0-9                                                         #
#  - Contains underscore (but not as first character)                            #
#                                                                                #
#  VERSION 1 - Initial Implementation                   04/07/2014 Graham Gold   #
#                                                                                #
##################################################################################
#>

#Main loop, runs until the password contains at least 1 underscore
Do {
#initialise variables
$pass=$null;
$passlen=$null;

#generate password length (windows needs minimum of 8 characters so 8-11
$passlen = Get-Random -Count 1 -InputObject (8..11);

#Get random number in range 48-57 (ASCII 0-9) or 65-90 (ASCII A-Z),
# get the ascii character and add to the password
Get-Random -Count 1 -InputObject (48..57+65..90) | % {$pass=$pass+[char]$_};

#Get passlen -1 random numbers in range 48-57 (ASCII 0-9) or 65-90 (ASCII A-Z)
#  or 95 (ASCII _ ) and for each, get the actual character matching that code
# and add to the password
Get-Random -Count ($passlen-1) -InputObject (48..57+65..90+95) | foreach {$pass=$pass+[char]$_}
    } until ($pass.Contains("_"))

#create outlook application object
$ol = New-Object -comObject Outlook.Application

#call CreateItem method of object to create new email
$mail = $ol.CreateItem(0)

#Set body to be the password
$mail.Body = $pass

#set sensitivity to Private (so mail is encrypted)
$Mail.Sensitivity = 2

#Get and display the email that has been created, so subject and to: address can be
# filled out and the email sent
$inspector = $mail.GetInspector
$inspector.Display()