#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the delete command for the external Linux/UNIX 
#   application.
#
#   The delete command is an input command. The IDM engine sends the delete 
#   command to the subscriber to request that the external application delete
#   an entry.  The delete command must contain an ASSOCIATION element.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry to delete, in the name 
#     space of eDirectory.
#
#   DEST_DN
#     Spceifies the distinguished name of the entry in the name space of the 
#     receiver.
#
#   DEST_ENTRY_ID
#     Spceifies the entry ID for the entry in the name space of the receiver.
#
#   CLASS_NAME
#     Specifies the base class of the entry being deleted.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the 
#     command.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry in the external application.
#
#
# REPLY FORMAT
#
#    The receiving application should respond to the modify with a STATUS
#    and an optional STATUS_MESSAGE which can be returned for IDM engine 
#    processing and logging facilities.
#
#    The format for returning STATUS and STATUS_MESSAGE are as follows:
#
#      $idmlib->status_<level>("<optional message>");
#
#        <level> may be one of the following values:
#        * success
#        * warning
#        * error
#        * retry
#        * fatal
#
#      Note:  fatal will shutdown the driver, retry will retry the event
#             later on.
#

use strict;
use IDMLib;

use lib "/opt/novell/usdrv/scripts";

our $global_config;

# include the IDM Library
my $idmlib = new IDMLib();

eval ( 'require "connectionManager.pl";' );
if($@){ 
   $idmlib->status_fatal("Error including connectionManager");
}

$idmlib->logger($global_config->{TRACEPRIO}, "delete.pl", " *** delete.pl *** ");
$idmlib->trace(" *** delete.pl *** ");

my $CLASS_NAME = $idmlib->idmgetvar("CLASS_NAME");
my $iuname = $idmlib->idmgetvar("ASSOCIATION");

# get Google apps login credentials
my $apiuser = $idmlib->idmgetdrvvar("api-provisioning-user");
my $domain = $idmlib->idmgetdrvvar("domain-name");
my $apipassword = $idmlib->idmsubgetnamedpassword("APIUserPassword");


#check valid input lengths
if(length($iuname) < 1 || length($iuname) > 50)
{
   $idmlib->status_error("Invalid user name length");
   exit;
}
#check valid username
if(!($iuname =~ /[a-z]{1,}/i))
{
   $idmlib->status_error("Username contains invalid characters");
   exit;
}

my $conMan = connectionManager->new($domain, $apiuser, $apipassword);
if (!$conMan->getAuthToken()) {
   $idmlib->status_error("Failed to get authentication token.  Be sure all required perl modules are installed and your userid and password are correct.");
   exit;
}
$conMan->connType("DELETE");
my $builtURL =  'https://www.google.com/a/feeds/'.$conMan->domain.'/user/2.0/'.$iuname;

$conMan->url($builtURL);
$conMan->send();

my $ecode = "";
my $emessg = "";

if(defined($conMan->returnedError))
{
   $ecode = substr($conMan->returnedError,0,4);
   $emessg = $conMan->returnedErrorMsg;
   chomp($ecode);
   $idmlib->status_error($ecode.": ".$emessg);
   exit;
}
else { $idmlib->status_success("OK"); }
