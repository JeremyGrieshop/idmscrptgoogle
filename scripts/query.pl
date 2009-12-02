#!/usr/bin/perl
#
# DESCRIPTION
#
#   This script implements the query for the external application, Linux/UNIX.  
#
#   The query command is an input command or event. A query is used to find 
#   and read information about entries in the external application, therefore
#   it is both a "search" and a "read" operation.
#
#
# VARIABLES
#
#   SCOPE
#     Specifies the extent of the search.  This attribute supports
#     the following values:  
#       * subtree - indicates to search the base entry and all entries
#         in its branch of the directory tree.  If no scoope is specified,
#         subtree is used as the default value.
#       * subordinates - indicates to search the immediate subordinates of 
#         the base entry (the base entry is not searched).
#       * entry - indicates to search just the base entry.
#     For scopes other than entry, the selected entries can be further
#     limited by the SEARCH_CLASSES and SEARCH_ATTR_ elements.  For scopes of
#     entry, the SEARCH_CLASSES and SEARCH_ATTR_ elements are ignored.
#     
#   DEST_DN
#     Specifies the distinguished name for the starting point for the search.
#     If both the DEST_DN attribute and ASSOCIATION have values, the 
#     ASSOCIATION value is used as the starting point for the search.  If 
#     neither have values, the search begins at the root of the directory.
#
#   CLASS_NAME
#     Specififes the base class of the DEST_DN attribute.
#
#   EVENT_ID
#     Specifies an identifier used to identify a particular instance of the 
#     command or event.
#
#   ASSOCIATION
#     Specifies the unique identifier for the entry where the search begins.  
#     If  both the DEST_DN attribute and the ASSOCIATION have values, the 
#     ASSOCIATION value is used as the starting point for the search.  If 
#     neither have values, the search begins at the root of the directory.
#
#   SEARCH_CLASSES
#     Specifies the search filter for object classes.  If the query contains no
#     SEARCH_CLASSES elements, all entries matching the scope and the 
#     SEARCH_ATTR_ elements are returned.
# 
#   SEARCH_ATTRS
#     Contains a list of the SEARCH_ATTR_ attribute names.
#
#   SEARCH_ATTR_<ATTR_NAME>
#     Specifies the search filter for attribute values.  If more than one 
#     SEARCH_ATTR_ element is specified, the entry must match all attributes
#     to be returned.  
#
#     <ATTR_NAME> will be replaced by the literal name of the attribute, 
#     upper-cased and non-printable characters converted to underscores.
#
#   READ_ATTRS
#     Specifies which attribute values are returned with entries that match
#     the search filters.
#
#   ALL_READ_ATTRS
#     Specifies that all readable attributes should be returned.
#
#   NO_READ_ATTRS
#     Specifies that no attributes are to be returned.
#
#   READ_PARENT
#     Specifies whether the parent of the entry is returned with the entry.
#
#
# REPLY FORMAT
#
#   The receiving application should respond to the query with an INSTANCE 
#   command for each entry returned.  The response should also include a
#   status indicating whether the query was processed successfully.
#   A query should return a successful status even when no entries exist
#   that match the search criteria.
#
#   The format for the INSTANCE command is as follows:
#
#     $imdlib->idmsetvar("COMMAND" "INSTANCE");         (zero or more)
#     $imdlib->idmsetvar("CLASS_NAME", $class-name);    (mandatory)
#     $imdlib->idmsetvar("SRC_DN", $src-dn);            (optional)
#     $imdlib->idmsetvar("ASSOCIATION", $association);  (optional)
#     $imdlib->idmsetvar("PARENT", $parent);            (optional)
#     $imdlib->idmsetvar("ATTR_attribute", $value);     (zero or more)
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
#      Note:  fatal will shutdown the driver, retry will retry the event
#             later on.
#

use strict;
use IDMLib;

use LWP::UserAgent;
use HTTP::Request::Common;

use lib "/opt/novell/usdrv/scripts";

our $global_config;

# include the IDM Library
my $idmlib = new IDMLib();

eval ( 'require "connectionManager.pl";' );
if($@){ 
   $idmlib->status_fatal("Error including connectionManager");
}

$idmlib->logger($global_config->{TRACEPRIO}, "query.pl", " *** query.pl *** ");
$idmlib->trace(" *** query.pl *** ");

# retrieve information from the query event 
my $SCOPE = $idmlib->idmgetvar("SCOPE");  #should always be 'entry' since everything else applies only to heirarchal systems
my $CLASS_NAME = $idmlib->idmgetvar("CLASS_NAME");  #should always be 'user'
my $ASSOCIATION = $idmlib->idmgetvar("ASSOCIATION");
my $DEST_DN = $idmlib->idmgetvar("DEST_DN");
my @SEARCH_CLASSES = $idmlib->idmgetvar("SEARCH_CLASS");
my @READ_ATTRS = $idmlib->idmgetvar("READ_ATTRS");

# get Google apps login credentials
my $apiuser = $idmlib->idmgetdrvvar("api-provisioning-user");
my $domain = $idmlib->idmgetdrvvar("domain-name");
my $apipassword = $idmlib->idmsubgetnamedpassword("APIUserPassword");


my $READ_ATTR;
my $SEARCH_CLASS;
my $newEntry;
my $entry;


# check the query scope
if ($SCOPE eq "entry") {
   # entry scope queries ask about a particular object

   # check for an association, if the object has already 
   # been associated
   my $SEARCH_BASE = "";
   if ($ASSOCIATION ne "") {
      # the association was created by the scripts and should
      # be sufficient in determining this particular object's
      # class type (CLASS_NAME).

      # the search base for our query is the association for
      # the sample skeleton scripts
      $SEARCH_BASE = $ASSOCIATION;
   } else {
      # without an association, we can use the DEST_DN field to
      # determine the search base for our query
    
      $SEARCH_BASE = $DEST_DN;
   }

   # now we should have a search base determined
   if ($SEARCH_BASE ne "") {

      # INSERT CUSTOM CODE HERE
      # Read the object $SEARCH_BASE which identifies the object
      # name we're interested in reading.  Create an association
      # string for this object that can be used to uniquely identify
      # the object.
    
      $idmlib->trace(" QUERY::SEARCH_BASE = ".$SEARCH_BASE);
    
      my $conMan = connectionManager->new($domain, $apiuser, $apipassword);
      if (!$conMan->getAuthToken()) {
         $idmlib->status_error("Failed to get authentication token.  Be sure all required perl modules are installed and your userid and password are correct.");
         exit;
      }

      $conMan->connType("GET");
      my $builtURL = 'https://www.google.com/a/feeds/'.$conMan->domain.'/user/2.0/'.$SEARCH_BASE;

      $conMan->url($builtURL);
      $conMan->send();
      
	
      #if object is found
      my $newEntry = userEntry->new();
      if (!(defined($conMan->returnedError))){
         $newEntry->fromXML($conMan->returned);
         $idmlib->idmsetvar("COMMAND", "INSTANCE");
         $idmlib->idmsetvar("CLASS_NAME", $CLASS_NAME);
         $idmlib->idmsetvar("ASSOCIATION", $SEARCH_BASE);
      }

      #end addition
    
      # If the object is found, return:
      #$idmlib->idmsetvar("COMMAND", "instance");
      #$idmlib->idmsetvar("EVENT_ID", $EVENT_ID);
      #$idmlib->idmsetvar("SRC_DN", $SEARCH_BASE);
      #$idmlib->idmsetvar("CLASS_NAME", $CLASS_NAME);
      #$idmlib->idmsetvar("ASSOCIATION", $ASSOCIATION);

      # check for which attributes to return (read)
      my $ALL_READ_ATTRS = $idmlib->idmgetvar("ALL_READ_ATTRS");
      if ($ALL_READ_ATTRS eq "true") {
         # return all attributes that can be read
         $idmlib->trace(" QUERY::ALL_READ_ATTRS = ".$ALL_READ_ATTRS);
         $idmlib->idmsetvar("ATTR_FNAME",$newEntry->firstName);
         $idmlib->idmsetvar("ATTR_LNAME",$newEntry->lastName);
         $idmlib->idmsetvar("ATTR_SUSPENDED",$newEntry->suspended);
         $idmlib->status_success();

         #$idmlib->idmsetvar("ATTR_attr1", "value1");
         #$idmlib->idmsetvar("ATTR_attr2", "value2");
      } else {
         # return only those attributes which are requested
         my $i=0;
         foreach $READ_ATTR (@READ_ATTRS) {
            # INSERT CUSTOM CODE HERE
            $idmlib->trace(" QUERY::READ_ATTR::".$i." = ".$READ_ATTR);
         
            if ($READ_ATTR eq "FNAME") {
               $idmlib->idmsetvar("ATTR_FNAME",$newEntry->firstName);
            } elsif ($READ_ATTR eq "LNAME") {
               $idmlib->idmsetvar("ATTR_LNAME",$newEntry->lastName);
            } elsif ($READ_ATTR eq "SUSPENDED") {
               $idmlib->idmsetvar("ATTR_SUSPENDED",$newEntry->suspended);
            }
            $i++;
         }
         $idmlib->status_success();
      } 
   } else {
      $idmlib->status_error("Unable to derive a search base");
   }
} else {
   # we have a subtree or subordinate query search
   foreach $SEARCH_CLASS (@SEARCH_CLASSES) {
   
      my $SEARCH_BASE = "";
      if ($ASSOCIATION ne "") {
         # the association was created by the scripts and should
         # be sufficient in determining this particular object's
         # class type (CLASS_NAME).

         # the search base for our query is the association for
         # the sample skeleton scripts
         $SEARCH_BASE = $ASSOCIATION;
      } else {
         # without an association, we can use the DEST_DN field to
         # determine the search base for our query
    
         $SEARCH_BASE = $DEST_DN;
      }

      # 
      # Search for the object defined by this particular
      # SEARCH_CLASS and SEARCH_ATTRS.  Return zero or more
      # instances along with a status document indicating the
      # level of success.
      #
    
      my $conMan = connectionManager->new($domain, $apiuser, $apipassword);
      if (!$conMan->getAuthToken()) {
         $idmlib->status_error("Failed to get authentication token.  Be sure all required perl modules are installed and your userid and password are correct.");
         exit;
      }
      $conMan->connType("GET");

      my $startuser = "";
      my $builtURL = 'https://www.google.com/a/feeds/'.$conMan->domain.'/user/2.0/'.$SEARCH_BASE;

      $conMan->url($builtURL);
      $conMan->send();
      
	
      #if object is found
      my $newEntry = userEntry->new();
      if (!(defined($conMan->returnedError))){
         $newEntry->fromXML($conMan->returned);
         $idmlib->idmsetvar("COMMAND", "INSTANCE");
         $idmlib->idmsetvar("CLASS_NAME", $CLASS_NAME);
         $idmlib->idmsetvar("ASSOCIATION", $SEARCH_BASE);
      }
      else {
         exit;
      }
      
      # check for which attributes to return (read)
      my $ALL_READ_ATTRS = $idmlib->idmgetvar("ALL_READ_ATTRS");
      if ($ALL_READ_ATTRS eq "true") {
         # return all attributes that can be read
         $idmlib->trace(" QUERY::ALL_READ_ATTRS = ".$ALL_READ_ATTRS);
         $idmlib->idmsetvar("ATTR_FNAME",$newEntry->firstName);
         $idmlib->idmsetvar("ATTR_LNAME",$newEntry->lastName);
         $idmlib->idmsetvar("ATTR_SUSPENDED",$newEntry->suspended);
         $idmlib->status_success();

         #$idmlib->idmsetvar("ATTR_attr1", "value1");
         #$idmlib->idmsetvar("ATTR_attr2", "value2");
      } else {
         # return only those attributes which are requested
         my $i=0;
         foreach $READ_ATTR (@READ_ATTRS) {
            # INSERT CUSTOM CODE HERE
            $idmlib->trace(" QUERY::READ_ATTR::".$i." = ".$READ_ATTR);
         
            if ($READ_ATTR eq "FNAME") {
               $idmlib->idmsetvar("ATTR_FNAME",$newEntry->firstName);
            } elsif ($READ_ATTR eq "LNAME") {
               $idmlib->idmsetvar("ATTR_LNAME",$newEntry->lastName);
            } elsif ($READ_ATTR eq "SUSPENDED") {
               $idmlib->idmsetvar("ATTR_SUSPENDED",$newEntry->suspended);
            }
            $i++;
         }
         $idmlib->status_success();
      } 
   }
}

# For the skeleton script, simply return a "Not Implemented" status
#$idmlib->status_warning("Not Implemented");
