#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the modify command for the external Linux/UNIX 
#   application.
#
#   The modify command is an input command.  The IDM engine sends a modify 
#   command to the subscriber to request that the external application modify
#   an entry.  The modify command must contain an ASSOCIATION element.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry to modify in the name
#     space of eDirectory.
#
#   CLASS_NAME
#     Specifies the base class of the entry being modified.  This attribute
#     is required for modify events.
#
#   EVENT_ID
#     Specifies an identifier to identify a particular instance of the command.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry in the external
#     application.  This element is required for modify events.
#
#   ADD_<ATTR_NAME>
#     Specifies one or more values to add to <ATTR_NAME>, where <ATTR_NAME> is
#     literally replaced by the name of the attribute being modified.
#
#   REMOVE_<ATTR_NAME>
#     Specifies one or more values to remove to <ATTR_NAME>, where <ATTR_NAME>
#     is literally replaced by the name of the attribute being modified.
#
#   REMOVE_ALL_<ATTR_NAME>
#     Instructs to remove all values associated with <ATTR_NAME>, where 
#     <ATTR_NAME> is literally replaced by the name of the attribute being 
#     modified.
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

# include the IDM Library
my $idmlib = new IDMLib();

eval ( 'require "connectionManager.pl";' );
if($@){ 
   print "> Error Including Connection Manager: $@\n";
   $idmlib->status_fatal("Error including connectionManager");
}

our $global_config;

$idmlib->logger($global_config->{TRACEPRIO}, "modify.pl", " *** modify.pl *** ");
$idmlib->trace(" *** modify.pl *** ");

my $CLASS_NAME = $idmlib->idmgetvar("CLASS_NAME");

# CUSTOM HERE ======================================
my $iuname = $idmlib->idmgetvar("ASSOCIATION");

#check valid input lengths
if(length($iuname) < 1 || length($iuname) > 50)
{
   $idmlib->status_error("400: Invalid username length");
   exit;
}
#check valid username
if(!($iuname =~ /[a-z]{1,}/i))
{
   $idmlib->status_error("400: Username contains invalid characters");
   exit;
}


my $ifname = undef;
my $ilname = undef;
my $isuspn = undef;
my $enable = undef;
my $disable = undef;
my $junk = undef;

$ifname = $idmlib->idmgetvar("FNAME");
$ilname = $idmlib->idmgetvar("LNAME");
$isuspn = $idmlib->idmgetvar("SUSPENDED");
($isuspn, $junk) = split("\n", $isuspn);

# get Google apps login credentials
my $apiuser = $idmlib->idmgetdrvvar("api-provisioning-user");
my $domain = $idmlib->idmgetdrvvar("domain-name");
my $apipassword = $idmlib->idmsubgetnamedpassword("APIUserPassword");



#replace set fields
my $obj = userEntry->new();
$obj->firstName($ifname);
$obj->lastName($ilname);
$obj->suspended($isuspn);

my $conMan = connectionManager->new($domain, $apiuser, $apipassword);
if (!$conMan->getAuthToken()) {
   $idmlib->status_error("Failed to get authentication token.  Be sure all required perl modules are installed and your userid and password are correct.");
   exit;
}
$conMan->connType("PUT");
my $builtURL = 'https://www.google.com/a/feeds/'.$conMan->domain.'/user/2.0/'.$iuname;
$conMan->xml($obj->toXML."\n");

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
else {  $idmlib->status_success("OK"); }
exit;
