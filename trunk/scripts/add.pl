#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the add command for the external Linux/UNIX
#   application.
#
#   The add command is an input command.  The IDM engine sends an add command 
#   to the subscriber shim to request that the external application add an 
#   entry.
#
#
# VARIABLES
#
#   SRC_DN
#     Specifies the distinguished name of the entry to add, in the name space
#     of eDirectory.  When the IDM engine sends the add command, the subscriber
#     should copy the SRC_DN attribute to the outgoing DEST_DN command.
#
#   SRC_ENTRY_ID
#     Specifies the entry ID of the entry that generated the add event.  It is
#     specified in the name space of eDirectory.  When the IDM engine sends 
#     the add command, the subscriber should copy the SRC_ENTRY_ID attribute
#     to the outgoing DEST_ENTRY_ID command.
#
#   CLASS_NAME
#     Specifies the base class of the entry being added.
#
#   TEMPLATE_DN
#     Specifies the distinguished name, in the subscriber's name space, of the
#     template to use when creating the entry.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the 
#     command.
#
#   ADD_<ATTR_NAME>
#     Specifies an attribute name/value to add with the entry, where 
#     <ATTR_NAME> is literally replaced by the name of the attribute being
#     added.
#
#   PASSWORD
#     Specifies the initial password for the entry.
#
#
# REPLY FORMAT
#
#    The receiving application should respond to the add with a STATUS_LEVEL
#    and if the add suceeded, the subscriber must also return an ASSOCIATION.
#    Optionally, a STATUS_MESSAGE may also be returned to pass string messages
#    to the IDM engine for processing and logging.
#
#    If the add event does not contain values for all attributes defined in 
#    the create rules, the IDM engine discards the add command for the entry.
#    When a modify command is received for this entry, IDM queries eDirectory
#    for the missing attributes.  If all attributes now have values, IDM 
#    changes the modify into an add command.
#
#    The format for returning ASSOCIATION, DEST_DN, DEST_ENTRY_ID, EVENT_ID, 
#    STATUS, STATUS_MESSAGE are as follows:
#
#      $idmlib->idmsetvar("ASSOCIATION", $<association>);
#      $idmlib->idmsetvar("DEST_DN", $<dest_dn>);
#      $idmlib->idmsetvar("DEST_ENTRY_ID", $<dest_entry_id>);
#      $idmlib->idmsetvar("EVENT_ID", $<event_id>);
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
use Mail::Sendmail;
use POSIX;

use lib "/opt/novell/usdrv/scripts";
our $global_config;

# include the IDM Library
my $idmlib = new IDMLib();

$idmlib->logger($global_config->{TRACEPRIO}, "add.pl", " *** dd.pl *** ");
$idmlib->trace(" *** add.pl *** ");

eval ( 'require "connectionManager.pl";' );
if($@){ 
   $idmlib->status_fatal("Error including connectionManager");
}

# retrieve any necessary information from the shim, such as CLASS_NAME of
# of the object being added
my $CLASS_NAME = $idmlib->idmgetvar("CLASS_NAME");

#custom code from here
my $SRC_DN = $idmlib->idmgetvar('SRC_DN');
my $SRC_ENTRY_ID = $idmlib->idmgetvar('SRC_ENTRY_ID');

my $iuname = $idmlib->idmgetvar("ADD_CN");
my $ipassw = $idmlib->idmgetvar("ADD_PASSWORD");
my $ifname = $idmlib->idmgetvar("ADD_FNAME");
my $ilname = $idmlib->idmgetvar("ADD_LNAME");

# get Google apps login credentials
my $apiuser = $idmlib->idmgetdrvvar("api-provisioning-user");
my $domain = $idmlib->idmgetdrvvar("domain-name");
my $apipassword = $idmlib->idmsubgetnamedpassword("APIUserPassword");

#print "[$apiuser, $domain, $apipassword]\n";


if(!($ifname) or $ifname eq "")
{
   $ifname = "Noname";
}

#check valid input lengths
if(length($iuname) < 1 || length($iuname) > 50 || length($ipassw) < 3 || length($ipassw) > 50)
{
   $idmlib->status_error("Invalid username or password length");
   exit;
}
#check valid username
if(!($iuname =~ /[a-z]{1,}/i))
{
   $idmlib->status_error("Username contains invalid characters");
   exit;
}


my $obj = userEntry->new();
$obj->userName($iuname);
$obj->password($ipassw);
$obj->firstName($ifname);
$obj->lastName($ilname);
$obj->suspended("false");

my $conMan = connectionManager->new($domain, $apiuser, $apipassword);
if (!$conMan->getAuthToken) {
   $idmlib->status_error("Failed to get authentication token.  Be sure all required perl modules are installed and your userid and password are correct.");
   exit;
}

$conMan->connType("POST");
my $builtURL = 'https://www.google.com/a/feeds/'.$conMan->domain.'/user/2.0';
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
else { 
  $idmlib->idmsetvar("COMMAND", "ADD_ASSOCIATION");
  $idmlib->idmsetvar("ASSOCIATION", $iuname);
  $idmlib->idmsetvar("DEST_DN", $SRC_DN);
  $idmlib->idmsetvar("DEST_ENTRY_ID", $SRC_ENTRY_ID);
  $idmlib->idmsetvar("EVENT_ID", time() );
  $idmlib->status_success("OK"); 
}

my $obj = sendThisMail($iuname.'@'.$domain);

sub sendThisMail{
	my $to = shift;
	
        # get email message info
        my $smtp_server = $idmlib->idmgetdrvvar("smtp-server");
        my $replyto = $idmlib->idmgetdrvvar("reply-to");
        my $subject = $idmlib->idmgetdrvvar("email-subject");
        my $body = $idmlib->idmgetdrvvar("email-body");
        
	my %mail = ("To"      => $to,
		"From"	=> $replyto,
		"Subject"	=> $subject,
		"smtp" 	=> $smtp_server,
		"Message"	=> $body
		);
		
	sendmail(%mail) or die $Mail::Sendmail::error;
}

1;
exit;
